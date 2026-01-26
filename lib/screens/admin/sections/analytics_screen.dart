import 'package:flutter/material.dart';
import '../../../models/admin_models.dart';
import '../../../services/admin_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  AnalyticsData? _analytics;
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsData = await AdminService.getAnalytics();
      
      // Check for errors in the response
      if (analyticsData.containsKey('error')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading analytics: ${analyticsData['error']}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
      
      setState(() {
        // Convert Map to AnalyticsData model
        _analytics = AnalyticsData(
          totalUsers: analyticsData['totalUsers'] as int? ?? 0,
          activeUsers: analyticsData['activeUsers'] as int? ?? 0,
          premiumCount: 0, // TODO: Add premium tracking
          totalLessonsCompleted: analyticsData['totalLessonsCompleted'] as int? ?? 0,
          topLessons: (analyticsData['topLessons'] as List?)
                  ?.map((e) => LessonPopularity(
                        lessonId: e['id'] as String? ?? '',
                        title: e['title'] as String? ?? '',
                        category: e['category'] as String? ?? '',
                        language: e['language'] as String? ?? '',
                        completions: e['completions'] as int? ?? 0,
                        avgScore: (e['avg_score'] as num?)?.toDouble() ?? 0.0,
                        avgTimeSeconds: (e['avg_time_seconds'] as num?)?.toDouble() ?? 0.0,
                      ))
                  .toList() ??
              [],
          averageDailyTime: 0.0, // TODO: Calculate
          retentionRate: (analyticsData['onboardingCompletionRate'] as num?)?.toDouble() ?? 0.0,
        );
        _analyticsData = analyticsData; // Store full data for display
        _isLoading = false;
      });
      
      // Debug: Print analytics data
      debugPrint('Analytics loaded - Total Users: ${analyticsData['totalUsers']}');
      debugPrint('Analytics loaded - Lessons Completed: ${analyticsData['totalLessonsCompleted']}');
      debugPrint('Analytics loaded - Active Users: ${analyticsData['activeUsers']}');
      debugPrint('Full analytics data: $analyticsData');
    } catch (e, stackTrace) {
      debugPrint('Error loading analytics: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reporting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('No data available'))
              : RefreshIndicator(
                  onRefresh: _loadAnalytics,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Stats cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total Users',
                              _analytics!.totalUsers.toString(),
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Active Users (7d)',
                              _analytics!.activeUsers.toString(),
                              Icons.trending_up,
                              Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Lessons Completed',
                              _analytics!.totalLessonsCompleted.toString(),
                              Icons.check_circle,
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Premium Users',
                              _analytics!.premiumCount.toString(),
                              Icons.star,
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Top lessons
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Top 5 Popular Lessons',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_analytics!.topLessons.isEmpty)
                                const Text('No data available')
                              else
                                ..._analytics!.topLessons.map((lesson) => ListTile(
                                      title: Text(lesson.title),
                                      subtitle: Text(
                                        '${lesson.category} • ${lesson.language}',
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '${lesson.completions} completions',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Avg: ${lesson.avgScore.toStringAsFixed(1)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // User Preferences Analytics
                      if (_analyticsData != null) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              const Text(
                                'User Preferences Analytics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildMetricRow(
                                'Onboarding Completion Rate',
                                '${((_analyticsData!['onboardingCompletionRate'] as num? ?? 0) * 100).toStringAsFixed(1)}%',
                              ),
                              const SizedBox(height: 16),
                              if (_analyticsData!['usersByLanguage'] != null)
                                _buildPreferenceSection(
                                  'Languages',
                                  _analyticsData!['usersByLanguage'] as Map<String, dynamic>,
                                ),
                              const SizedBox(height: 16),
                              if (_analyticsData!['usersByLevel'] != null)
                                _buildPreferenceSection(
                                  'Proficiency Levels',
                                  _analyticsData!['usersByLevel'] as Map<String, dynamic>,
                                ),
                              const SizedBox(height: 16),
                              if (_analyticsData!['usersByReason'] != null)
                                _buildPreferenceSection(
                                  'Learning Reasons',
                                  _analyticsData!['usersByReason'] as Map<String, dynamic>,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ],
                      // Additional metrics
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Engagement Metrics',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildMetricRow(
                                'Average Daily Time',
                                '${_analytics!.averageDailyTime.toStringAsFixed(1)} minutes',
                              ),
                              _buildMetricRow(
                                'Retention Rate',
                                '${(_analytics!.retentionRate * 100).toStringAsFixed(1)}%',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Icon(icon, color: color),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceSection(String title, Map<String, dynamic> data) {
    final entries = data.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key),
                  Text(
                    '${entry.value} users',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}

