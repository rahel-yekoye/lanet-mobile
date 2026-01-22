import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../widgets/speech_practice.dart';
import '../services/onboarding_service.dart';

class LessonScreen extends StatefulWidget {
  final Phrase phrase;
  const LessonScreen({super.key, required this.phrase});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  String? _selectedLanguage;
  String? _userLanguage;
  bool _showSpeechPractice = false;

  @override
  void initState() {
    super.initState();
    _loadUserLanguage();
  }

  Future<void> _loadUserLanguage() async {
    final language = await OnboardingService.getValue(OnboardingService.keyLanguage);
    setState(() {
      _userLanguage = language?.toLowerCase();
      // Set the selected language to the user's language
      if (language != null) {
        _selectedLanguage = _convertToInternalLanguage(language.toLowerCase());
      }
    });
  }

  String _convertToInternalLanguage(String userLang) {
    switch(userLang) {
      case 'amharic':
        return 'amharic';
      case 'tigrinya':
      case 'tigrigna':
        return 'tigrinya';
      case 'oromo':
      case 'oromigna':
        return 'oromo';
      default:
        return 'amharic';
    }
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            if (_userLanguage != null && _userLanguage!.toLowerCase() == 'amharic')
              _rowLabel('Amharic', widget.phrase.amharic),
            if (_userLanguage != null && _userLanguage!.toLowerCase() == 'oromo')
              _rowLabel('Oromo', widget.phrase.oromo),
            if (_userLanguage != null && (_userLanguage!.toLowerCase() == 'tigrinya' || _userLanguage!.toLowerCase() == 'tigrigna'))
              _rowLabel('Tigrinya', widget.phrase.tigrinya),
            const SizedBox(height: 30),
            
            // Only show language selector for speech practice if user has selected a language
            if (_userLanguage != null)
              Column(
                children: [
                  Text(
                    'Practice pronunciation in $_userLanguage:',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
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
