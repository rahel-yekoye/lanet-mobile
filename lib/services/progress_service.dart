import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import 'supabase_service.dart';

class ProgressService {
  static const _key = 'lanet_progress_v1';

  Future<Map<String, dynamic>> _read() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return {};
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<void> _write(Map<String, dynamic> m) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, json.encode(m));
  }

  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month}-${now.day}';
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  /// Get weekly XP data (last 7 days including today)
  Future<Map<String, int>> getWeeklyXP() async {
    final m = await _read();
    final daily = Map<String, dynamic>.from(m['daily'] ?? {});
    final weeklyData = <String, int>{};
    
    // Get last 7 days
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _dateKey(date);
      final xp = _asInt(daily[dateKey] ?? 0);
      weeklyData[dateKey] = xp;
    }
    
    return weeklyData;
  }

  Future<int> getDailyXP() async {
    final m = await _read();
    final day = _today();
    final daily = Map<String, dynamic>.from(m['daily'] ?? {});
    final v = daily[day] ?? 0;
    return _asInt(v);
  }

  Future<int> getStreak() async {
    final m = await _read();
    return _asInt(m['streak'] ?? 0);
  }

  Future<void> setStreak(int value) async {
    final m = await _read();
    m['streak'] = _asInt(value);
    await _write(m);
  }

  Future<int> getDailyGoal() async {
    final m = await _read();
    return _asInt(m['daily_goal'] ?? 5);
  }

  Future<void> setDailyGoal(int goal) async {
    final m = await _read();
    m['daily_goal'] = goal;
    await _write(m);
  }

  Future<bool> hasHitDailyGoalToday() async {
    final m = await _read();
    final day = _today();
    final hit = Map<String, dynamic>.from(m['goal_hit'] ?? {});
    return hit[day] == true;
  }

  Future<void> markDailyGoalHit() async {
    final m = await _read();
    final day = _today();
    final hit = Map<String, dynamic>.from(m['goal_hit'] ?? {});
    hit[day] = true;
    m['goal_hit'] = hit;
    await _write(m);
  }

  Future<int> getAchievementsCount() async {
    final m = await _read();
    final ach = Map<String, dynamic>.from(m['achievements'] ?? {});
    return ach.values.where((v) => v == true).length;
  }

  Future<void> addXP(int xp) async {
    final m = await _read();
    final day = _today();
    final daily = Map<String, dynamic>.from(m['daily'] ?? {});
    final cur = _asInt(daily[day] ?? 0);
    daily[day] = cur + xp;
    m['daily'] = daily;
    final goal = _asInt(m['daily_goal'] ?? 100);
    final hit = Map<String, dynamic>.from(m['goal_hit'] ?? {});
    if ((daily[day] as int) >= goal) {
      hit[day] = true;
      m['goal_hit'] = hit;
    }
    await _write(m);
    if (!SupabaseConfig.isDemoMode) {
      final latestXP = _asInt(daily[day]);
      final latestStreak = _asInt(m['streak'] ?? 0);
      // Also update total XP - fetch current total and add the new XP
      await _syncXPToSupabase(xp);
      await SupabaseService.updateProgress(
        dailyXP: latestXP,
        streak: latestStreak,
      );
    }
  }
 
  Future<void> setDailyXPForToday(int xp) async {
    final m = await _read();
    final day = _today();
    final daily = Map<String, dynamic>.from(m['daily'] ?? {});
    daily[day] = _asInt(xp);
    m['daily'] = daily;
    final goal = _asInt(m['daily_goal'] ?? 100);
    final hit = Map<String, dynamic>.from(m['goal_hit'] ?? {});
    if ((daily[day] as int) >= goal) {
      hit[day] = true;
      m['goal_hit'] = hit;
    }
    await _write(m);
  }

  Future<void> bumpStreakIfFirstSuccessToday() async {
    final m = await _read();
    final day = _today();
    final daily = Map<String, dynamic>.from(m['daily'] ?? {});
    final cur = _asInt(daily[day] ?? 0);
    if (cur == 0) {
      final streak = _asInt(m['streak'] ?? 0);
      m['streak'] = streak + 1;
      await _write(m);
      if (!SupabaseConfig.isDemoMode) {
        await SupabaseService.updateProgress(
          dailyXP: 0,
          streak: streak + 1,
        );
      }
    }
  }

  Future<List<String>> checkAndUnlockAchievements() async {
    final m = await _read();
    final day = _today();
    final daily = Map<String, dynamic>.from(m['daily'] ?? {});
    final curXP = _asInt(daily[day] ?? 0);
    final streak = _asInt(m['streak'] ?? 0);
    final ach = Map<String, dynamic>.from(m['achievements'] ?? {});

    final newly = <String>[];
    void unlock(String id) {
      if (ach[id] == true) return;
      ach[id] = true;
      newly.add(id);
    }

    if (streak >= 3) unlock('streak_3');
    if (streak >= 7) unlock('streak_7');
    if (streak >= 14) unlock('streak_14');
    if (curXP >= 50) unlock('xp_50');
    if (curXP >= 100) unlock('xp_100');
    if (curXP >= 200) unlock('xp_200');

    if (newly.isNotEmpty) {
      m['achievements'] = ach;
      if (newly.contains('streak_7')) {
        final ft = _asInt(m['freeze_tokens'] ?? 0);
        m['freeze_tokens'] = ft + 1;
      }
      await _write(m);
    }
    return newly;
  }

  Future<int> getFreezeTokens() async {
    final m = await _read();
    return _asInt(m['freeze_tokens'] ?? 0);
  }

  Future<bool> consumeFreezeToken() async {
    final m = await _read();
    final ft = _asInt(m['freeze_tokens'] ?? 0);
    if (ft > 0) {
      m['freeze_tokens'] = ft - 1;
      await _write(m);
      return true;
    }
    return false;
  }

  Future<void> applyDailyRollover() async {
    final m = await _read();
    final today = _today();
    final last = m['last_day'] as String?;
    if (last == today) return;
    final daily = Map<String, dynamic>.from(m['daily'] ?? {});
    final prevXP = _asInt(daily[last ?? today] ?? 0);
    if (last != null && prevXP == 0) {
      final used = await consumeFreezeToken();
      if (!used) {
        m['streak'] = 0;
        if (!SupabaseConfig.isDemoMode) {
          await SupabaseService.updateProgress(
            dailyXP: 0,
            streak: 0,
          );
        }
      }
    }
    m['last_day'] = today;
    await _write(m);
  }

  Future<int?> getHeartsRefillAt() async {
    final m = await _read();
    final v = m['hearts_refill_at'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  Future<void> setHeartsRefillAt(int ts) async {
    final m = await _read();
    m['hearts_refill_at'] = ts;
    await _write(m);
  }

  Future<void> clearHeartsRefill() async {
    final m = await _read();
    m.remove('hearts_refill_at');
    await _write(m);
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? 0;
    }
    return 0;
  }

  Future<void> _syncXPToSupabase(int delta) async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final row = await SupabaseService.client
          .from('users')
          .select('xp')
          .eq('id', uid)
          .maybeSingle();
      final currentXP = _asInt(row?['xp']);
      final newXP = currentXP + delta;
      await SupabaseService.client
          .from('users')
          .update({'xp': newXP})
          .eq('id', uid);
    } catch (_) {}
  }

  Future<void> _syncStreakToSupabase(int newStreak) async {
    final uid = SupabaseService.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await SupabaseService.client
          .from('users')
          .update({'streak': newStreak})
          .eq('id', uid);
    } catch (_) {}
  }
}
