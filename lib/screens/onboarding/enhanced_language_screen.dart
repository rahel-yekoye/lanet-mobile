import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/animated_bg.dart';
import '../../widgets/fade_page.dart';
import '../../models/user_preferences.dart';

class EnhancedLanguageScreen extends StatefulWidget {
  const EnhancedLanguageScreen({super.key});

  @override
  State<EnhancedLanguageScreen> createState() => _EnhancedLanguageScreenState();
}

class _EnhancedLanguageScreenState extends State<EnhancedLanguageScreen> {
  final List<String> selectedLanguages = [];

  final languages = const [
    {'name': 'Amharic', 'code': 'am', 'flag': '🇪🇹'},
    {'name': 'Oromo', 'code': 'om', 'flag': '🇪🇹'},
    {'name': 'Tigrinya', 'code': 'ti', 'flag': '🇪🇷'},
    {'name': 'English', 'code': 'en', 'flag': '🇬🇧'},
    {'name': 'Somali', 'code': 'so', 'flag': '🇸🇴'},
    {'name': 'Arabic', 'code': 'ar', 'flag': '🇸🇦'},
    {'name': 'French', 'code': 'fr', 'flag': '🇫🇷'},
    {'name': 'Spanish', 'code': 'es', 'flag': '🇪🇸'},
  ];

  void _toggleLanguage(String languageCode) {
    setState(() {
      if (selectedLanguages.contains(languageCode)) {
        selectedLanguages.remove(languageCode);
      } else {
        selectedLanguages.add(languageCode);
      }
    });
  }

  void _continue() {
    if (selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one language')),
      );
      return;
    }

    // Save preferences and navigate
    context.push('/onboarding/knowledge-level', extra: selectedLanguages);
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
                  Text(
                    "🌍 What would you like to learn?",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Select languages",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "You can choose multiple languages",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: languages.length,
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        final isSelected = selectedLanguages.contains(lang['code']);
                        
                        return InkWell(
                          onTap: () => _toggleLanguage(lang['code']!),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
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
                            child: Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    lang['flag']!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    lang['name']!,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.black87
                                          : Colors.white,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      },
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
                      child: Text(
                        'Continue (${selectedLanguages.length})',
                        style: const TextStyle(
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
