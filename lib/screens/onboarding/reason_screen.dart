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
      currentStep: 3,
      totalSteps: 4,
      child: ListView(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What\'s Your Motivation?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a reason to help personalize your lessons',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 24),
              ...reasons
                  .map((reason) => _buildReasonOption(reason, context)),
            ],
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

          // Small delay to ensure state is updated before navigation
          // This prevents router from redirecting during navigation
          await Future.delayed(const Duration(milliseconds: 100));

          if (context.mounted) {
            // Use go() instead of push() to ensure clean navigation
            // The router will see we're on an onboarding route and allow it
            context.go('/onboarding/daily_goal');
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
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
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
