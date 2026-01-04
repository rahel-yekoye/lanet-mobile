import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../widgets/speech_practice.dart';

class LessonScreen extends StatefulWidget {
  final Phrase phrase;
  const LessonScreen({required this.phrase});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String? _selectedLanguage;
  bool _showSpeechPractice = false;

  @override
  void initState() {
    super.initState();
    // Default to first language
    _selectedLanguage = 'amharic';
  }

  String _getTargetText() {
    switch (_selectedLanguage) {
      case 'amharic':
        return widget.phrase.amharic;
      case 'oromo':
        return widget.phrase.oromo;
      case 'tigrinya':
        return widget.phrase.tigrinya;
      default:
        return widget.phrase.amharic;
    }
  }

  void _onSpeechResult(bool correct) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(correct ? 'Excellent pronunciation! 🎉' : 'Keep practicing! 💪'),
        backgroundColor: correct ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSpeechPractice) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Practice Pronunciation'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              setState(() {
                _showSpeechPractice = false;
              });
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SpeechPractice(
            prompt: widget.phrase.english,
            targetText: _getTargetText(),
            onResult: _onSpeechResult,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phrase'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              widget.phrase.english,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _rowLabel('Amharic', widget.phrase.amharic),
            _rowLabel('Oromo', widget.phrase.oromo),
            _rowLabel('Tigrinya', widget.phrase.tigrinya),
            const SizedBox(height: 30),
            
            // Language selector for speech practice
            const Text(
              'Practice pronunciation in:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _languageChip('Amharic', 'amharic'),
                const SizedBox(width: 8),
                _languageChip('Oromo', 'oromo'),
                const SizedBox(width: 8),
                _languageChip('Tigrinya', 'tigrinya'),
              ],
            ),
            
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.mic, size: 28),
              label: const Text(
                'Practice Pronunciation',
                style: TextStyle(fontSize: 18),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showSpeechPractice = true;
                });
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _languageChip(String label, String value) {
    final isSelected = _selectedLanguage == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedLanguage = value;
        });
      },
      selectedColor: Colors.teal.shade300,
      checkmarkColor: Colors.white,
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
