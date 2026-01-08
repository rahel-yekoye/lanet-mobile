import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/choice_card.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';

class DailyGoalScreen extends StatelessWidget {
  const DailyGoalScreen({super.key});

  final goals = const ["5 minutes", "10 minutes", "15 minutes", "20 minutes"];

  static int _parseGoalToMinutes(String goal) {
    // Extract the number from the goal string (e.g., "5 minutes" -> 5)
    final number = goal.split(' ')[0];
    return int.tryParse(number) ?? 5;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBG(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FadeSlide(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Icon(Icons.timer, size: 60, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "Set your daily goal",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: goals
                          .map((goal) => ChoiceCard(
                                label: goal,
                                onTap: () async {
                                  await OnboardingService.setValue(OnboardingService.keyGoal, goal);
                                  await OnboardingService.completeOnboarding();
                                  
                                  // Get all selections to save to database
                                  final selections = await OnboardingService.getSelections();
                                  
                                  try {
                                    // Update user profile with onboarding preferences
                                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                    
                                    // Extract values explicitly to ensure correct typing and debug
                                    final languageValue = selections['language'];
                                    final levelValue = selections['level'];
                                    final reasonValue = selections['reason'];
                                    final dailyGoalValue = _parseGoalToMinutes(goal);
                                    
                                    debugPrint('Updating profile with:');
                                    debugPrint('  language: $languageValue (${languageValue.runtimeType})');
                                    debugPrint('  level: $levelValue (${levelValue.runtimeType})');
                                    debugPrint('  reason: $reasonValue (${reasonValue.runtimeType})');
                                    debugPrint('  dailyGoal: $dailyGoalValue (${dailyGoalValue.runtimeType})');
                                    
                                    await authProvider.updateProfile(
                                      language: languageValue,
                                      level: levelValue,
                                      reason: reasonValue,
                                      dailyGoal: dailyGoalValue,
                                    );
                                  } catch (e, stackTrace) {
                                    debugPrint('Error updating user profile: $e');
                                    debugPrint('Stack trace: $stackTrace');
                                  }
                                  
                                  context.go('/home');
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}