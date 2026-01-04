import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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
      await _write(m);
    }
    return newly;
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? 0;
    }
    return 0;
  }
}
