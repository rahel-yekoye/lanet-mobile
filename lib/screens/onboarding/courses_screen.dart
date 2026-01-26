import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/lesson_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/onboarding_scaffold.dart';
import '../../widgets/onboarding_progress_indicator.dart';
import '../../models/phrase.dart';
import '../../services/onboarding_service.dart';
import '../lesson_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key}); 

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initLoad();
  }

  Future<void> _initLoad() async {
    if (_initialized) return;
    _initialized = true;

    final lp = Provider.of<LessonProvider>(context, listen: false);
    final prefsProvider = Provider.of<UserPreferencesProvider>(context, listen: false);

    if (prefsProvider.hasPreferences && prefsProvider.preferences != null) {
      final prefs = prefsProvider.preferences!;
      await lp.reload(
        'assets/data/multilingual_dataset.json',
        context: context,
        preferences: prefs,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LessonProvider>(context);
    final prefsProvider = Provider.of<UserPreferencesProvider>(context);

    return OnboardingScaffold(
      title: 'Recommended Courses',
      child: Column(
        children: [
          const OnboardingProgressIndicator(
            currentStep: 5,
            totalSteps: 5,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: lp.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: lp.categories.length,
                    itemBuilder: (context, index) {
                      final category = lp.categories[index];
                      final phrases = lp.phrasesFor(category);
                      return _buildCourseCard(context, category, phrases);
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final prefsProvider = Provider.of<UserPreferencesProvider>(context, listen: false);
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  if (prefsProvider.preferences != null) {
                    final p = prefsProvider.preferences!;
                    await authProvider.markOnboardingCompleted(
                      language: p.preferredLanguage ?? '',
                      level: p.proficiencyLevel ?? '',
                      reason: p.learningReasons.join(','),
                      dailyGoal: p.dailyGoalMinutes,
                    );
                  } else {
                    final selections = await OnboardingService.getSelections();
                    final language = selections['language'] ?? '';
                    final level = selections['level'] ?? '';
                    final reason = selections['reason'] ?? '';
                    final goalStr = selections['goal'] ?? '5';
                    final goal = int.tryParse(goalStr) ?? 5;
                    await authProvider.markOnboardingCompleted(
                      language: language,
                      level: level,
                      reason: reason,
                      dailyGoal: goal,
                    );
                  }
                  await OnboardingService.completeOnboarding();
                  context.go('/home');
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Start Learning',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, String category, List<Phrase> phrases) {
    final count = phrases.length;
    final color = _getCategoryColor(category);
    final icon = _getCategoryIcon(category);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count phrases',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () {
                if (phrases.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No lessons in $category yet')),
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _LessonLauncher(phrase: phrases[0]),
                  ),
                );
              },
              child: const Text('Start'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = [
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.teal,
    ];
    return colors[category.hashCode % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('greeting')) return Icons.waving_hand;
    if (lower.contains('emergency')) return Icons.warning;
    if (lower.contains('romance')) return Icons.favorite;
    if (lower.contains('hotel') || lower.contains('restaurant')) return Icons.restaurant;
    return Icons.school;
  }
}

class _LessonLauncher extends StatelessWidget {
  final Phrase phrase;
  const _LessonLauncher({required this.phrase});

  @override
  Widget build(BuildContext context) {
    // Reuse existing LessonScreen with first phrase of category
    return Navigator(
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) => LessonScreen(phrase: phrase),
        );
      },
    );
  }
}
