import 'package:flutter/material.dart';
import '../models/phrase.dart';

class LessonScreen extends StatelessWidget {
  final Phrase phrase;
  const LessonScreen({super.key, required this.phrase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(phrase.english, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _rowLabel('Amharic', phrase.amharic),
            _rowLabel('Oromo', phrase.oromo),
            _rowLabel('Tigrinya', phrase.tigrinya),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.record_voice_over),
              label: const Text('Practice (quiz)'),
              onPressed: () {
                // open practice for this single phrase (or add to session)
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowLabel(String lang, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(lang, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
      ],
    );
  }
}
