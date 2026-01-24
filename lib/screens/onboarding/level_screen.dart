import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
                    'What\'s Your Level?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select the level that best describes you',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...levels.map((level) => _buildLevelOption(level, context)),
                ],
              ),
            ),
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
          level,
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
          await OnboardingService.setValue(OnboardingService.keyLevel, level);
          context.push('/onboarding/reason');
        },
      ),
    );
  }
}