import 'dart:math';
import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../services/srs_service.dart';
import '../widgets/multiple_choice.dart';

class PracticeScreen extends StatefulWidget {
  final String category;
  final List<Phrase> phrases;
  const PracticeScreen({super.key, required this.category, required this.phrases});

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
      });
      return;
    }
    current = pool.removeLast();
    // generate choices using target language (e.g. Oromo)
    // For variety, randomly pick one target language per question
    final targetLang = ['amharic', 'oromo', 'tigrinya'][rnd.nextInt(3)];
    // build options
    final allOptions = <String>{};
    allOptions.add(_valueFor(current!, targetLang));
    while (allOptions.length < 4) {
      final randomPhrase = widget.phrases[rnd.nextInt(widget.phrases.length)];
      allOptions.add(_valueFor(randomPhrase, targetLang));
    }
    final ops = allOptions.toList();
    ops.shuffle();
    choices = ops;
    correctIndex = ops.indexWhere((o) => o == _valueFor(current!, targetLang));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Correct ✔️')));
    } else {
      await srs.markWrong(widget.category, current!.english);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wrong ✖️ — will be repeated')));
    }
    // small delay then next
    await Future.delayed(const Duration(milliseconds: 600));
    if (pool.isEmpty) {
      // refresh pool (simple behavior)
      pool = List.from(widget.phrases)..shuffle();
    }
    _nextQuestion();
  }

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Practice: ${widget.category}')),
        body: const Center(child: Text('No questions (or finished).')),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Practice: ${widget.category}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: MultipleChoice(
          prompt: current!.english,
          options: choices,
          correctIndex: correctIndex,
          onAnswer: _onAnswer,
        ),
      ),
    );
  }
}
