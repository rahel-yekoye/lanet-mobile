import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../services/progress_service.dart';
import '../widgets/pattern_background.dart';
import 'package:go_router/go_router.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen> {
  final ProgressService _progressService = ProgressService();
  int _dailyXP = 0;
  int _totalXP = 0; // Total XP across all time
  int _streak = 0;
  int _dailyGoal = 100;
  int _achievementsCount = 0;
  bool _goalHitToday = false;
  int _freezeTokens = 0;
  final List<String> _recentAchievements = [];
  RealtimeChannel? _progressChannel;
  Map<String, int> _weeklyXP = {};

  @override
  void initState() {
    super.initState();
    _loadProgressData();
    _subscribeRealtime();
  }

  Future<void> _loadProgressData() async {
    // Local fast read
    var dailyXP = await _progressService.getDailyXP();
    var streak = await _progressService.getStreak();
    var dailyGoal = await _progressService.getDailyGoal();
    final achievementsCount = await _progressService.getAchievementsCount();
    final goalHitToday = await _progressService.hasHitDailyGoalToday();
    final freezeTokens = await _progressService.getFreezeTokens();
    final weeklyXP = await _progressService.getWeeklyXP();

    // Load total XP and overlay server values if available
    int totalXP = 0;
    if (!SupabaseConfig.isDemoMode) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        if (data != null) {
          final sDaily = data['daily_xp_earned'];
          final sStreak = data['streak'];
          final sGoal = data['daily_goal'];
          final sTotalXP = data['xp'];
          if (sDaily is num) dailyXP = sDaily.toInt();
          if (sStreak is num) streak = sStreak.toInt();
          if (sGoal is num) dailyGoal = sGoal.toInt();
          if (sTotalXP is num) totalXP = sTotalXP.toInt();
        }
      }
    }

    if (mounted) {
      setState(() {
        _dailyXP = dailyXP;
        _totalXP = totalXP;
        _streak = streak;
        _dailyGoal = dailyGoal;
        _achievementsCount = achievementsCount;
        _goalHitToday = goalHitToday;
        _freezeTokens = freezeTokens;
        _weeklyXP = weeklyXP;
      });
    }
  }

  void _subscribeRealtime() {
    if (SupabaseConfig.isDemoMode) return;
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    
    try {
      // Unsubscribe from existing channel if any
      if (_progressChannel != null) {
        try {
          _progressChannel?.unsubscribe();
        } catch (e) {
          debugPrint('Error unsubscribing existing channel: $e');
        }
        _progressChannel = null;
      }
      
      // Use a unique channel name to avoid conflicts
      final channelName = 'progress_${userId}_${DateTime.now().millisecondsSinceEpoch}';
      _progressChannel = client
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'users',
            callback: (payload) {
              if (!mounted) return;
              try {
                final rec = payload.newRecord;
                final rid = rec['id'];
                // Only process updates for current user
                if (rid != userId) return;
                final sDaily = rec['daily_xp_earned'];
                final sStreak = rec['streak'];
                final sGoal = rec['daily_goal'];
                final sTotalXP = rec['xp'];
                if (mounted) {
                  setState(() {
                    if (sDaily is num) _dailyXP = sDaily.toInt();
                    if (sStreak is num) _streak = sStreak.toInt();
                    if (sGoal is num) _dailyGoal = sGoal.toInt();
                    if (sTotalXP is num) _totalXP = sTotalXP.toInt();
                  });
                }
              } catch (e) {
                debugPrint('Error processing realtime update: $e');
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error subscribing to realtime updates: $e');
    }
  }

  @override
  void dispose() {
    // Safely unsubscribe from realtime channel
    try {
      _progressChannel?.unsubscribe();
    } catch (e) {
      // Ignore errors during disposal - channel may already be closed
      debugPrint('Error unsubscribing from progress channel: $e');
    }
    _progressChannel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PatternBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Your Progress'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () {
              // Navigate back to home using router to ensure correct behavior
              GoRouter.of(context).go('/home');
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _loadProgressData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Daily Progress Card
              _buildDailyProgressCard(),

              const SizedBox(height: 16),

              // Streak Card
              _buildStreakCard(),

              const SizedBox(height: 16),

              // Achievements Section
              _buildAchievementsSection(),

              const SizedBox(height: 16),

              // Stats Overview
              _buildStatsOverview(),

              const SizedBox(height: 16),

              // Weekly Activity (Placeholder)
              _buildWeeklyActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyProgressCard() {
    final progressPercent = (_dailyXP / _dailyGoal).clamp(0.0, 1.0);
    final remainingXP =
        (_dailyGoal - _dailyXP).clamp(0, double.infinity).toInt();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daily Goal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_goalHitToday)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text('Completed',
                            style: TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            Stack(
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: progressPercent,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$_dailyXP / $_dailyGoal XP',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (!_goalHitToday)
                  Text(
                    '$remainingXP XP to go',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),

            if (!_goalHitToday && remainingXP > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progressPercent,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Current Streak',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department,
                    size: 32,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔥 $_streak days',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _streak == 1
                          ? 'Keep it going!'
                          : _streak < 7
                              ? 'Almost to your first week!'
                              : 'Amazing dedication!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_freezeTokens > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ac_unit,
                            size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          '$_freezeTokens',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events,
                    size: 28,
                    color: Colors.purple.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_achievementsCount unlocked',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Keep practicing to unlock more!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 16,
              alignment: WrapAlignment.spaceAround,
              children: [
                _buildStatItem('🔥', 'Streak', _streak.toString()),
                _buildStatItem('⭐', 'XP Today', _dailyXP.toString()),
                _buildStatItem('🏆', 'Total XP', _totalXP.toString()),
                _buildStatItem('🎯', 'Goal', _dailyGoal.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String emoji, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildWeeklyActivity() {
    // Get day names for the last 7 days
    final now = DateTime.now();
    final dayNames = <String>[];
    final dayData = <int>[];
    int maxXP = 0;
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final xp = _weeklyXP[dateKey] ?? 0;
      dayData.add(xp);
      if (xp > maxXP) maxXP = xp;
      
      // Get day name (Mon, Tue, etc.)
      final dayName = _getDayName(date.weekday);
      dayNames.add(dayName);
    }
    
    // Ensure maxXP is at least 1 to avoid division by zero
    if (maxXP == 0) maxXP = 1;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            
            // Chart
            if (_weeklyXP.isEmpty)
              Container(
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '📊 No activity data yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final xp = dayData[index];
                    final height = (xp / maxXP) * 120; // Max height 120
                    final isToday = index == 6;
                    
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Bar
                            Container(
                              height: height.clamp(4.0, 120.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: isToday
                                      ? [
                                          Colors.blue.shade600,
                                          Colors.blue.shade400,
                                        ]
                                      : [
                                          Colors.blue.shade400,
                                          Colors.blue.shade300,
                                        ],
                                ),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                              child: xp > 0
                                  ? Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Padding(
                                          padding: const EdgeInsets.all(2.0),
                                          child: Text(
                                            '$xp',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            // Day label
                            Text(
                              dayNames[index],
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                color: isToday
                                    ? Colors.blue.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            
            const SizedBox(height: 12),
            
            // Summary
            if (_weeklyXP.isNotEmpty)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Total: ${dayData.reduce((a, b) => a + b)} XP this week',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
