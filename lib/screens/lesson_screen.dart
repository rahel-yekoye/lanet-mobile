import 'package:flutter/material.dart';
import '../models/phrase.dart';

class LessonScreen extends StatelessWidget {
  final Phrase phrase;
  const LessonScreen({required this.phrase});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Phrase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(phrase.english, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            _rowLabel('Amharic', phrase.amharic),
            _rowLabel('Oromo', phrase.oromo),
            _rowLabel('Tigrinya', phrase.tigrinya),
            Spacer(),
            ElevatedButton.icon(
              icon: Icon(Icons.record_voice_over),
              label: Text('Practice (quiz)'),
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
        Text(lang, style: TextStyle(fontSize: 14, color: Colors.grey)),
        SizedBox(height: 4),
        Text(text, style: TextStyle(fontSize: 18)),
        SizedBox(height: 12),
      ],
    );
  }
}
