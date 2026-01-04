import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/choice_card.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';

class LevelScreen extends StatelessWidget {
  const LevelScreen({super.key});

  final levels = const ["Beginner", "Intermediate", "Advanced"];

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
                  const Icon(Icons.star, size: 60, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "Your Level",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: levels
                          .map((level) => ChoiceCard(
                                label: level,
                                onTap: () async {
                                  await OnboardingService.setValue(OnboardingService.keyLevel, level);
                                  context.push('/onboarding/reason');
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