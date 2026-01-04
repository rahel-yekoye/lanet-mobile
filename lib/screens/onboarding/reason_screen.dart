import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/choice_card.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';

class ReasonScreen extends StatelessWidget {
  const ReasonScreen({super.key});

  final reasons = const ["Travel", "Study", "Work", "Culture", "Personal Growth"];

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
                  const Icon(Icons.favorite, size: 60, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text(
                    "Why are you learning?",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: reasons
                          .map((reason) => ChoiceCard(
                                label: reason,
                                onTap: () async {
                                  await OnboardingService.setValue(OnboardingService.keyReason, reason);
                                  context.push('/onboarding/daily_goal');
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