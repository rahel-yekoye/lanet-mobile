import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/onboarding_scaffold.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  final levels = const ["Beginner", "Intermediate", "Advanced"];

  Color _getLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'beginner':
        return Colors.green.shade100.withOpacity(0.4);
      case 'intermediate':
        return Colors.yellow.shade100.withOpacity(0.4);
      case 'advanced':
        return Colors.red.shade100.withOpacity(0.4);
      default:
        return Colors.purple.shade100.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Your Level',
      currentStep: 2,
      totalSteps: 4,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What\'s Your Level?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the level that best describes you',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              ...levels.map((level) => _buildLevelOption(level, context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelOption(String level, BuildContext context) {
    IconData icon;
    Color iconColor;
    String description;

    switch (level.toLowerCase()) {
      case 'beginner':
        icon = Icons.school;
        iconColor = Colors.green;
        description = 'Just starting out';
        break;
      case 'intermediate':
        icon = Icons.auto_stories;
        iconColor = Colors.orange;
        description = 'Some experience';
        break;
      case 'advanced':
        icon = Icons.workspace_premium;
        iconColor = Colors.red;
        description = 'Fluent speaker';
        break;
      default:
        icon = Icons.question_mark;
        iconColor = Colors.grey;
        description = 'Other';
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
          print('DEBUG: Level Selected: $level');
          await OnboardingService.setValue(OnboardingService.keyLevel, level);

          // Incrementally save to backend
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            await authProvider.updateProfile(level: level);
          } catch (e) {
            debugPrint('Error saving level incrementally: $e');
          }

          if (context.mounted) {
            context.push('/onboarding/reason');
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
                        level,
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
