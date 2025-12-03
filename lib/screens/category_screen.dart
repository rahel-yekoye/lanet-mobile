import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import 'lesson_screen.dart';
import 'practice_screen.dart';
import '../widgets/phrase_card.dart';

class CategoryScreen extends StatefulWidget {
  final String category;
  const CategoryScreen({required this.category, super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  // Default selected languages
  List<String> selectedLanguages = ["Amharic", "Oromo", "Tigrinya"];

  // Opens dialog to select visible languages
void _chooseLanguages() async {
  final languages = ["Amharic", "Oromo", "Tigrinya"];
  List<String> tempSelected = List.from(selectedLanguages);

  final result = await showDialog<List<String>>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setStateDialog) {
          return AlertDialog(
            title: const Text("Select languages"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: languages.map((lang) {
                return CheckboxListTile(
                  value: tempSelected.contains(lang),
                  title: Text(lang),
                  onChanged: (val) {
                    setStateDialog(() {
                      if (val == true) {
                        tempSelected.add(lang);
                      } else {
                        tempSelected.remove(lang);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, tempSelected),
                child: const Text("OK"),
              )
            ],
          );
        },
      );
    },
  );

  if (result != null) {
    setState(() {
      selectedLanguages = result;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final lp = Provider.of<LessonProvider>(context);
    final phrases = lp.phrasesFor(widget.category);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category),
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            tooltip: "Choose languages",
            onPressed: _chooseLanguages,
          )
        ],
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
                return PhraseCard(
                  phrase: p,
                  visibleLanguages: selectedLanguages,
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
