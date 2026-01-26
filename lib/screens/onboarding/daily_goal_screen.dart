import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/lesson_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/onboarding_scaffold.dart';

class DailyGoalScreen extends StatelessWidget {
  const DailyGoalScreen({super.key});

  final goals = const ["5 minutes", "10 minutes", "15 minutes", "20 minutes"];

  static int _parseGoalToMinutes(String goal) {
    // Extract the number from the goal string (e.g., "5 minutes" -> 5)
    final number = goal.split(' ')[0];
    return int.tryParse(number) ?? 5;
  }

  Color _getGoalColor(String goal) {
    switch (goal.toLowerCase()) {
      case '5 minutes':
        return Colors.green.shade100.withOpacity(0.4);
      case '10 minutes':
        return Colors.blue.shade100.withOpacity(0.4);
      case '15 minutes':
        return Colors.orange.shade100.withOpacity(0.4);
      case '20 minutes':
        return Colors.red.shade100.withOpacity(0.4);
      default:
        return Colors.purple.shade100.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Set your daily goal',
      currentStep: 4,
      totalSteps: 4,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Your Daily Goal',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how much time you want to study each day',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              ...goals.map((goal) => _buildGoalOption(goal, context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption(String goal, BuildContext context) {
    IconData icon;
    Color iconColor;
    String description;
    
    switch (goal.toLowerCase()) {
      case '5 minutes':
        icon = Icons.timelapse;
        iconColor = Colors.green;
        description = 'Quick daily practice';
        break;
      case '10 minutes':
        icon = Icons.access_time;
        iconColor = Colors.blue;
        description = 'Moderate commitment';
        break;
      case '15 minutes':
        icon = Icons.hourglass_bottom;
        iconColor = Colors.orange;
        description = 'Solid foundation';
        break;
      case '20 minutes':
        icon = Icons.timer;
        iconColor = Colors.red;
        description = 'Deep learning';
        break;
      default:
        icon = Icons.question_mark;
        iconColor = Colors.grey;
        description = 'Custom time';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        color: Colors.white,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
          print('DEBUG: Daily Goal Selected: $goal');
          await OnboardingService.setValue(OnboardingService.keyGoal, goal);
          await OnboardingService.completeOnboarding();

          final selections = await OnboardingService.getSelections();
          final languageValue = selections['language'];
          final levelValue = selections['level'];
          final reasonValue = selections['reason'];
          final dailyGoalValue = _parseGoalToMinutes(goal);

          // Ensure we have all four values before proceeding
          if (languageValue == null || languageValue.isEmpty ||
              levelValue == null || levelValue.isEmpty ||
              reasonValue == null || reasonValue.isEmpty) {
            debugPrint('ERROR: Missing onboarding data - language: $languageValue, level: $levelValue, reason: $reasonValue');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please complete all onboarding steps'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }

          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            
            // Mark onboarding as completed - this saves all four fields to Supabase
            // This will create/update entries in user_preferences table with:
            // - language_<value> (e.g., language_Tigrinya)
            // - level_<value> (e.g., level_Intermediate)
            // - reason_<value> (e.g., reason_Travel)
            // - daily_goal_<value> (e.g., daily_goal_10)
            await authProvider.markOnboardingCompleted(
              language: languageValue,
              level: levelValue,
              reason: reasonValue,
              dailyGoal: dailyGoalValue,
            );
            
            debugPrint('✅ All onboarding data saved to Supabase:');
            debugPrint('   - Language: $languageValue');
            debugPrint('   - Level: $levelValue');
            debugPrint('   - Reason: $reasonValue');
            debugPrint('   - Daily Goal: $dailyGoalValue minutes');
            
            // Wait longer for auth state to fully update and onboarding flag to be set
            await Future.delayed(const Duration(milliseconds: 500));
          } catch (e, stackTrace) {
            debugPrint('❌ Error saving onboarding data to Supabase: $e');
            debugPrint('Stack trace: $stackTrace');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error saving preferences: ${e.toString()}'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return; // Don't navigate if save failed
          }

          // Load lessons now that onboarding is complete
          if (context.mounted) {
            final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
            const assetPath = 'assets/data/multilingual_dataset.json';
            final languageForLessons = languageValue.toLowerCase() ?? '';
            await lessonProvider.load(assetPath, language: languageForLessons.isNotEmpty ? languageForLessons : null);
            
            // Wait a bit more to ensure router sees the updated state
            await Future.delayed(const Duration(milliseconds: 300));
            
            if (context.mounted) {
              // Navigate to home - router will handle proper redirection
              context.go('/home');
            }
          }
        },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
