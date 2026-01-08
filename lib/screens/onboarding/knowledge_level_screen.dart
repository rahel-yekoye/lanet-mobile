import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';
import '../../models/user_preferences.dart';

class KnowledgeLevelScreen extends StatefulWidget {
  final List<String> selectedLanguages;

  const KnowledgeLevelScreen({
    super.key,
    required this.selectedLanguages,
  });

  @override
  State<KnowledgeLevelScreen> createState() => _KnowledgeLevelScreenState();
}

class _KnowledgeLevelScreenState extends State<KnowledgeLevelScreen> {
  String? currentLanguage;
  Map<String, KnowledgeLevel> languageLevels = {};
  int currentLanguageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.selectedLanguages.isNotEmpty) {
      currentLanguage = widget.selectedLanguages[0];
    }
  }

  void _selectLevel(KnowledgeLevel level) {
    if (currentLanguage == null) return;

    setState(() {
      languageLevels[currentLanguage!] = level;
    });

    // Move to next language or continue
    if (currentLanguageIndex < widget.selectedLanguages.length - 1) {
      setState(() {
        currentLanguageIndex++;
        currentLanguage = widget.selectedLanguages[currentLanguageIndex];
      });
    } else {
      _continue();
    }
  }

  void _continue() {
    // Verify all languages have levels
    for (final lang in widget.selectedLanguages) {
      if (!languageLevels.containsKey(lang)) {
        // Set default level if not set
        languageLevels[lang] = KnowledgeLevel.newToLanguage;
      }
    }

    context.push(
      '/onboarding/learning-reason',
      extra: {
        'languages': widget.selectedLanguages,
        'levels': languageLevels,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageName = _getLanguageName(currentLanguage ?? '');

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
                  Text(
                    "📊 How much do you know about $languageName?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Language ${currentLanguageIndex + 1} of ${widget.selectedLanguages.length}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: ListView(
                      children: KnowledgeLevel.values.map((level) {
                        final isSelected = currentLanguage != null &&
                            languageLevels[currentLanguage] == level;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _selectLevel(level),
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
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          level.title,
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
                                          level.description,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getLanguageName(String code) {
    final names = {
      'am': 'Amharic',
      'om': 'Oromo',
      'ti': 'Tigrinya',
      'en': 'English',
      'so': 'Somali',
      'ar': 'Arabic',
      'fr': 'French',
      'es': 'Spanish',
    };
    return names[code] ?? code.toUpperCase();
  }
}
