import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/choice_card.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  final languages = const ["English", "Amharic", "Oromo", "Tigrinya", "Somali"];

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
                  const SizedBox(height: 30),
                  Text(
                    "🌍 Let's get started",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Choose your language",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Expanded(
                    child: ListView(
                      children: languages
                          .map((lang) => ChoiceCard(
                                label: lang,
                                onTap: () => context.push('/onboarding/level'),
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
