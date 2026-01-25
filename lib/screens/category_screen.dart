import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import 'lesson_screen.dart';
import 'practice_screen.dart';
import '../widgets/phrase_card.dart';
import '../services/onboarding_service.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  const CategoryScreen({required this.category, super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String? userLanguage;

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    final language = await OnboardingService.getValue(OnboardingService.keyLanguage);
    setState(() {
      userLanguage = language;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LessonProvider>(context);
    final phrases = lp.phrasesFor(widget.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: userLanguage != null ? [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Displaying content in ${userLanguage!}",
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Currently displaying content in ${userLanguage!}"),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          )
        ] : [],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Practice (SRS)'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PracticeScreen(
                      category: widget.category,
                      phrases: phrases,
                      targetLanguage: userLanguage?.toLowerCase(),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: phrases.length,
              itemBuilder: (context, i) {
                final p = phrases[i];
                final visibleLanguages = userLanguage != null ? [userLanguage!] : ["Amharic", "Oromo", "Tigrinya"];
                return PhraseCard(
                  phrase: p,
                  visibleLanguages: visibleLanguages,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LessonScreen(phrase: p),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
