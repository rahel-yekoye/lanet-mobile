import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';
import '../../models/learning_reason.dart';
import '../../models/user_preferences.dart';

class LearningReasonScreen extends StatefulWidget {
  final List<String> languages;
  final Map<String, KnowledgeLevel> levels;

  const LearningReasonScreen({
    super.key,
    required this.languages,
    required this.levels,
  });

  @override
  State<LearningReasonScreen> createState() => _LearningReasonScreenState();
}

class _LearningReasonScreenState extends State<LearningReasonScreen> {
  Map<String, String> selectedReasons = {};

  void _toggleReason(String language, String reasonId) {
    setState(() {
      selectedReasons[language] = reasonId;
    });
  }

  void _continue() {
    // Set default reason if not selected
    for (final lang in widget.languages) {
      if (!selectedReasons.containsKey(lang)) {
        selectedReasons[lang] = 'fun'; // Default
      }
    }

    context.push(
      '/onboarding/daily-goal-enhanced',
      extra: {
        'languages': widget.languages,
        'levels': widget.levels,
        'reasons': selectedReasons,
      },
    );
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
                    "🎯 Why are you learning?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select your main reason for learning ${widget.languages.length > 1 ? 'these languages' : 'this language'}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView(
                      children: LearningReason.reasons.map((reason) {
                        final isSelected = widget.languages.any(
                          (lang) => selectedReasons[lang] == reason.id,
                        );

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              // Apply to all selected languages
                              for (final lang in widget.languages) {
                                _toggleReason(lang, reason.id);
                              }
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
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
                                  Text(
                                    reason.icon,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          reason.title,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          reason.description,
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
                                      size: 28,
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
                      onPressed: _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue',
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
