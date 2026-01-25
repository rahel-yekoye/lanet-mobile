import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/onboarding_scaffold.dart';

class ReasonScreen extends StatelessWidget {
  const ReasonScreen({super.key});

  final reasons = const [
    "Travel",
    "Study",
    "Work",
    "Culture",
    "Personal Growth"
  ];

  Color _getReasonColor(String reason) {
    switch (reason.toLowerCase()) {
      case 'travel':
        return Colors.blue.shade100.withOpacity(0.4);
      case 'study':
        return Colors.purple.shade100.withOpacity(0.4);
      case 'work':
        return Colors.orange.shade100.withOpacity(0.4);
      case 'culture':
        return Colors.pink.shade100.withOpacity(0.4);
      case 'personal growth':
        return Colors.teal.shade100.withOpacity(0.4);
      default:
        return Colors.grey.shade100.withOpacity(0.4);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      title: 'Why are you learning?',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s Your Motivation?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pick a reason to help personalize your lessons',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...reasons
                      .map((reason) => _buildReasonOption(reason, context)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonOption(String reason, BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (reason.toLowerCase()) {
      case 'travel':
        icon = Icons.flight_takeoff;
        iconColor = Colors.blue;
        break;
      case 'study':
        icon = Icons.school;
        iconColor = Colors.purple;
        break;
      case 'work':
        icon = Icons.work;
        iconColor = Colors.orange;
        break;
      case 'culture':
        icon = Icons.museum;
        iconColor = Colors.pink;
        break;
      case 'personal growth':
        icon = Icons.self_improvement;
        iconColor = Colors.teal;
        break;
      default:
        icon = Icons.question_mark;
        iconColor = Colors.grey;
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
          reason,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () async {
          print('DEBUG: Reason Selected: $reason');
          await OnboardingService.setValue(OnboardingService.keyReason, reason);

          // Incrementally save to backend
          try {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            await authProvider.updateProfile(reason: reason);
          } catch (e) {
            debugPrint('Error saving reason incrementally: $e');
          }

          if (context.mounted) {
            context.push('/onboarding/daily_goal');
          }
        },
      ),
    );
  }
}
