import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set Your Daily Goal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose how much time you want to study each day',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...goals.map((goal) => _buildGoalOption(goal, context)),
                ],
              ),
            ),
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
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          goal,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () async {
          await OnboardingService.setValue(OnboardingService.keyGoal, goal);
          await OnboardingService.completeOnboarding();

          final selections = await OnboardingService.getSelections();
          try {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            final languageValue = selections['language'];
            final levelValue = selections['level'];
            final reasonValue = selections['reason'];
            final dailyGoalValue = _parseGoalToMinutes(goal);

            // Mark onboarding as completed
            await authProvider.markOnboardingCompleted(
              language: languageValue ?? '',
              level: levelValue ?? '',
              reason: reasonValue ?? '',
              dailyGoal: dailyGoalValue,
            );
            
            // Wait a moment for auth state to fully update
            await Future.delayed(const Duration(milliseconds: 100));
          } catch (e, stackTrace) {
            debugPrint('Error updating user profile: $e');
            debugPrint('Stack trace: $stackTrace');
          }

          // Navigate to home - router will handle proper redirection
          if (context.mounted) {
            context.go('/home');
          }
        },
      ),
    );
  }
}