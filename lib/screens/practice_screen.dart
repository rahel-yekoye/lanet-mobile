import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../services/srs_service.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../widgets/multiple_choice.dart';
import '../widgets/speech_practice.dart';

enum ExerciseType { multipleChoice, speech, listening }

class PracticeScreen extends StatefulWidget {
  final String category;
  final List<Phrase> phrases;
  const PracticeScreen(
      {super.key, required this.category, required this.phrases});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  late List<Phrase> pool;
  final rnd = Random();
  final SRSService srs = SRSService();
  final progress = ProgressService();
  int idx = 0;
  Phrase? current;
  List<String> choices = [];
  int correctIndex = 0;
  ExerciseType? currentExerciseType;
  String? currentTargetLang;
  int answered = 0;
  int correctCount = 0;
  int dailyXP = 0;
  int streak = 0;
  bool usedHint = false;
  int hintLevel = 0; // 0=no hint, 1=prefix(1), 2=prefix(2)
  int hearts = 5;
  final int maxHearts = 5;
  DateTime? questionShownAt;
  Timer? bonusTimer;
  int bonusCountdown = 10;

  @override
  void initState() {
    super.initState();
    pool = List.from(widget.phrases);
    pool.shuffle();
    _refreshProgress();
    _nextQuestion();
  }

  Future<void> _refreshProgress() async {
    dailyXP = await progress.getDailyXP();
    streak = await progress.getStreak();
    final unlocked = await progress.checkAndUnlockAchievements();
    if (unlocked.isNotEmpty && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🏅 Achievement unlocked: ${unlocked.first}')),
      );
    }
    setState(() {});
  }

  void _nextQuestion() {
    if (pool.isEmpty) {
      setState(() {
        current = null;
        currentExerciseType = null;
      });
      return;
    }
    usedHint = false;
    hintLevel = 0;
    questionShownAt = DateTime.now();
    bonusTimer?.cancel();
    bonusCountdown = 10;
    bonusTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        bonusCountdown = max(0, bonusCountdown - 1);
      });
      if (bonusCountdown == 0) {
        t.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('⏱ Bonus window ended')),
          );
        }
      }
    });
    current = pool.removeLast();

    // Randomly choose exercise type (MC, speech, or listening)
    final pick = rnd.nextInt(3);
    currentExerciseType = pick == 0
        ? ExerciseType.multipleChoice
        : pick == 1
            ? ExerciseType.speech
            : ExerciseType.listening;

    // For variety, randomly pick one target language per question
    currentTargetLang = ['amharic', 'oromo', 'tigrinya'][rnd.nextInt(3)];

    if (currentExerciseType == ExerciseType.multipleChoice ||
        currentExerciseType == ExerciseType.listening) {
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
      correctIndex =
          ops.indexWhere((o) => o == _valueFor(current!, currentTargetLang!));
    }

    setState(() {});
  }

  void _showHint() {
    if (current == null || currentTargetLang == null) return;
    final t = _valueFor(current!, currentTargetLang!);
    hintLevel = min(2, hintLevel + 1);
    usedHint = true;
    final masked = _maskedPreview(t, hintLevel);
    final hint = currentExerciseType == ExerciseType.multipleChoice
        ? 'Hint: $masked'
        : 'Speak: $masked';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(hint)),
    );
  }

  Future<void> _skipQuestion() async {
    if (current == null) return;
    await srs.markWrong(widget.category, current!.english);
    answered++;
    hearts = max(0, hearts - 1);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Skipped — no XP')));
    pool.insert(0, current!);
    await Future.delayed(const Duration(milliseconds: 300));
    _nextQuestion();
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
      correctCount++;
      answered++;
      await progress.bumpStreakIfFirstSuccessToday();
      int base = usedHint ? 5 : 10;
      int bonus = 0;
      if (!usedHint && questionShownAt != null) {
        final secs = DateTime.now().difference(questionShownAt!).inSeconds;
        if (secs <= 5) {
          bonus = 3;
        } else if (secs <= 10) {
          bonus = 1;
        }
      }
      await progress.addXP(base + bonus);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(usedHint
              ? 'Correct ✔️ +$base XP (hint)'
              : bonus > 0
                  ? 'Correct ✔️ +$base +$bonus XP (fast)'
                  : 'Correct ✔️ +$base XP')));
      hearts = min(maxHearts, hearts + 0); // keep hearts stable on correct
    } else {
      await srs.markWrong(widget.category, current!.english);
      answered++;
      await progress.addXP(2);
      hearts = max(0, hearts - 1);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong ✖️ — will be repeated (+2 XP)')));
      if (hearts == 0) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Out of hearts'),
              content: const Text('Take a short break or refill to continue.'),
              actions: [
                TextButton(
                  onPressed: () {
                    hearts = maxHearts;
                    Navigator.pop(ctx);
                  },
                  child: const Text('Refill'),
                ),
              ],
            ),
          );
        }
      }
    }
    await _refreshProgress();
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
    if (current == null || currentExerciseType == null) {
      return Scaffold(
        appBar: AppBar(
            title: Text('Practice: ${widget.category}'),
            actions: _progressChips()),
        body: const Center(child: Text('No questions (or finished).')),
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
          // Countdown chip (timed bonus)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text('⏱ $bonusCountdown s',
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: bonusCountdown > 5
                  ? Colors.green.shade100
                  : Colors.amber.shade100,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Hint',
            onPressed: _showHint,
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Skip',
            onPressed: _skipQuestion,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: Text('❤️ $hearts', style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.red.shade100,
            ),
          ),
          ..._progressChips(),
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
            : currentExerciseType == ExerciseType.listening
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🔊 Listen and choose the correct text'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final text = _valueFor(current!, currentTargetLang!);
                          final usedRemote = await TTSService()
                              .play(text, langCode: currentTargetLang);
                          if (!usedRemote && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Network issue — using fallback voice')),
                            );
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play'),
                      ),
                      const SizedBox(height: 12),
                      MultipleChoice(
                        prompt: 'Select the correct text',
                        options: choices,
                        correctIndex: correctIndex,
                        onAnswer: _onAnswer,
                      ),
                    ],
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

  List<Widget> _progressChips() {
    return [
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Chip(
          label: Text('🔥 $streak-day streak',
              style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.orange.shade100,
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Chip(
          label:
              Text('⭐ $dailyXP XP today', style: const TextStyle(fontSize: 12)),
          backgroundColor: Colors.purple.shade100,
        ),
      ),
      FutureBuilder<int>(
        future: progress.getAchievementsCount(),
        builder: (context, snap) {
          final count = snap.data ?? 0;
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              label: Text('🏅 $count badges',
                  style: const TextStyle(fontSize: 12)),
              backgroundColor: Colors.yellow.shade100,
            ),
          );
        },
      ),
    ];
  }

  String _maskedPreview(String text, int level) {
    if (text.isEmpty) return '—';
    final reveal = level == 1 ? 1 : 2;
    final n = text.length;
    final prefix = text.substring(0, min(reveal, n));
    final masked = List.filled(max(0, n - prefix.length), '•').join();
    return '$prefix$masked  ($n chars)';
  }

  @override
  void dispose() {
    bonusTimer?.cancel();
    super.dispose();
  }
}
