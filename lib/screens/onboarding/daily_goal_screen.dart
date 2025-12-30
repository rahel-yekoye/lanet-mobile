import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/choice_card.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';

class DailyGoalScreen extends StatelessWidget {
  const DailyGoalScreen({super.key});

  final goals = const ["5 minutes", "10 minutes", "15 minutes", "20 minutes"];

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
                                onTap: () => context.go('/home'),
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
