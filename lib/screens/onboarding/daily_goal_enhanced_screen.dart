import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';
import '../../models/daily_goal.dart';
import '../../models/user_preferences.dart';

class DailyGoalEnhancedScreen extends StatefulWidget {
  final List<String> languages;
  final Map<String, KnowledgeLevel> levels;
  final Map<String, String> reasons;

  const DailyGoalEnhancedScreen({
    super.key,
    required this.languages,
    required this.levels,
    required this.reasons,
  });

  @override
  State<DailyGoalEnhancedScreen> createState() =>
      _DailyGoalEnhancedScreenState();
}

class _DailyGoalEnhancedScreenState extends State<DailyGoalEnhancedScreen> {
  int? selectedGoalMinutes;

  void _selectGoal(DailyGoal goal) {
    setState(() {
      selectedGoalMinutes = goal.minutes;
    });
  }

  void _complete() {
    if (selectedGoalMinutes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a daily goal')),
      );
      return;
    }

    // Save all preferences and navigate to welcome
    context.go('/welcome', extra: {
      'languages': widget.languages,
      'levels': widget.levels,
      'reasons': widget.reasons,
      'dailyGoal': selectedGoalMinutes,
    });
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
                  const SizedBox(height: 20),
                  const Text(
                    "⏰ What's your daily goal?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Practice makes perfect! Choose how much time you want to spend learning each day",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView(
                      children: DailyGoal.goals.map((goal) {
                        final isSelected = selectedGoalMinutes == goal.minutes;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectGoal(goal),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.blue
                                      : Colors.white.withOpacity(0.3),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade50
                                          : Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.timer,
                                      color: isSelected
                                          ? Colors.blue
                                          : Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.label,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'per day',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isSelected
                                                ? Colors.black54
                                                : Colors.white.withOpacity(0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 32,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _complete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Complete Setup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
