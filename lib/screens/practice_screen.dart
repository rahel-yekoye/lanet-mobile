import 'dart:math';
import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../services/srs_service.dart';
import '../widgets/multiple_choice.dart';
import '../widgets/speech_practice.dart';

enum ExerciseType { multipleChoice, speech }

class PracticeScreen extends StatefulWidget {
  final String category;
  final List<Phrase> phrases;
  const PracticeScreen({required this.category, required this.phrases});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late List<Phrase> pool;
  final rnd = Random();
  final srs = SRSService();
  int idx = 0;
  Phrase? current;
  List<String> choices = [];
  int correctIndex = 0;
  ExerciseType? currentExerciseType;
  String? currentTargetLang;

  @override
  void initState() {
    super.initState();
    pool = List.from(widget.phrases);
    pool.shuffle();
    _nextQuestion();
  }

  void _nextQuestion() {
    if (pool.isEmpty) {
      setState(() {
        current = null;
        currentExerciseType = null;
      });
      return;
    }
    current = pool.removeLast();
    
    // Randomly choose exercise type (50% multiple choice, 50% speech)
    currentExerciseType = rnd.nextBool() ? ExerciseType.multipleChoice : ExerciseType.speech;
    
    // For variety, randomly pick one target language per question
    currentTargetLang = ['amharic', 'oromo', 'tigrinya'][rnd.nextInt(3)];
    
    if (currentExerciseType == ExerciseType.multipleChoice) {
      // build options for multiple choice
      final allOptions = <String>{};
      allOptions.add(_valueFor(current!, currentTargetLang!));
      while (allOptions.length < 4) {
        final randomPhrase = widget.phrases[rnd.nextInt(widget.phrases.length)];
        allOptions.add(_valueFor(randomPhrase, currentTargetLang!));
      }
      final ops = allOptions.toList();
      ops.shuffle();
      choices = ops;
      correctIndex = ops.indexWhere((o) => o == _valueFor(current!, currentTargetLang!));
    }
    
    setState(() {});
  }

  String _valueFor(Phrase p, String lang) {
    switch (lang) {
      case 'amharic':
        return p.amharic;
      case 'oromo':
        return p.oromo;
      case 'tigrinya':
        return p.tigrinya;
      default:
        return p.amharic;
    }
  }

  void _onAnswer(bool correct) async {
    if (current == null) return;
    if (correct) {
      await srs.markCorrect(widget.category, current!.english);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Correct ✔️')));
    } else {
      await srs.markWrong(widget.category, current!.english);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Wrong ✖️ — will be repeated')));
    }
    // small delay then next
    await Future.delayed(Duration(milliseconds: 600));
    if (pool.isEmpty) {
      // refresh pool (simple behavior)
      pool = List.from(widget.phrases)..shuffle();
    }
    _nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    if (current == null || currentExerciseType == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Practice: ${widget.category}')),
        body: Center(child: Text('No questions (or finished).')),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice: ${widget.category}'),
        actions: [
          // Exercise type indicator
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text(
                currentExerciseType == ExerciseType.speech
                    ? '🎤 Speech'
                    : '📝 Multiple Choice',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: currentExerciseType == ExerciseType.speech
                  ? Colors.teal.shade100
                  : Colors.blue.shade100,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: currentExerciseType == ExerciseType.speech
            ? SpeechPractice(
                prompt: current!.english,
                targetText: _valueFor(current!, currentTargetLang!),
                onResult: _onAnswer,
              )
            : MultipleChoice(
                prompt: current!.english,
                options: choices,
                correctIndex: correctIndex,
                onAnswer: _onAnswer,
              ),
      ),
    );
  }
}
