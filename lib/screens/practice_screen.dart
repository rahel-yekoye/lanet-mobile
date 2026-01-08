import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../services/srs_service.dart';
import '../services/progress_service.dart';
import '../services/tts_service.dart';
import '../widgets/multiple_choice.dart';
import '../widgets/speech_practice.dart';

enum ExerciseType {
  multipleChoice,
  speech,
  listening,
  typeAnswer,
  tapComplete,
  matchPairs
}

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
  List<Phrase> wrongs = [];
  int dailyXP = 0;
  int streak = 0;
  bool usedHint = false;
  int hintLevel = 0; // 0=no hint, 1=prefix(1), 2=prefix(2)
  int hearts = 5;
  final int maxHearts = 5;
  DateTime? questionShownAt;
  Timer? bonusTimer;
  int bonusCountdown = 10;
  int dailyGoal = 100;
  bool goalToastShown = false;
  DateTime? heartsRefillAt;
  Timer? heartsTimer;
  final TextEditingController _typeController = TextEditingController();
  String tapBuild = '';
  List<String> matchLeft = [];
  List<String> matchRight = [];
  Set<int> matchSolved = {};
  int? matchSelL;
  int? matchSelR;

  @override
  void initState() {
    super.initState();
    pool = List.from(widget.phrases);
    pool.shuffle();
    _initDay();
    _nextQuestion();
  }

  Future<void> _initDay() async {
    await progress.applyDailyRollover();
    dailyGoal = await progress.getDailyGoal();
    final rts = await progress.getHeartsRefillAt();
    if (rts != null) {
      final when = DateTime.fromMillisecondsSinceEpoch(rts);
      if (when.isAfter(DateTime.now())) {
        heartsRefillAt = when;
        _startHeartsTimer();
      } else {
        await progress.clearHeartsRefill();
      }
    }
    await _refreshProgress();
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
    final hit = await progress.hasHitDailyGoalToday();
    if (!goalToastShown && dailyXP >= dailyGoal && !hit && mounted) {
      goalToastShown = true;
      await progress.markDailyGoalHit();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎯 Daily goal reached')),
      );
    }
    setState(() {});
  }

  void _nextQuestion() {
    if (pool.isEmpty) {
      _showSummary();
      pool = List.from(widget.phrases);
      pool.shuffle();
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
    final pick = rnd.nextInt(6);
    currentExerciseType = pick == 0
        ? ExerciseType.multipleChoice
        : pick == 1
            ? ExerciseType.speech
            : pick == 2
                ? ExerciseType.listening
                : pick == 3
                    ? ExerciseType.typeAnswer
                    : pick == 4
                        ? ExerciseType.tapComplete
                        : ExerciseType.matchPairs;

    // For variety, randomly pick one target language per question
    currentTargetLang = ['amharic', 'oromo', 'tigrinya'][rnd.nextInt(3)];

    if (currentExerciseType == ExerciseType.multipleChoice ||
        currentExerciseType == ExerciseType.listening ||
        currentExerciseType == ExerciseType.matchPairs) {
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
      if (currentExerciseType == ExerciseType.matchPairs) {
        const pairCount = 4;
        matchLeft = [];
        matchRight = [];
        matchSolved = {};
        for (int i = 0; i < pairCount; i++) {
          final p = widget.phrases[rnd.nextInt(widget.phrases.length)];
          matchLeft.add(p.english);
          matchRight.add(_valueFor(p, currentTargetLang!));
        }
        matchRight.shuffle();
        matchSelL = null;
        matchSelR = null;
      }
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
    if (hearts == 0) {
      final when = DateTime.now().add(const Duration(minutes: 10));
      heartsRefillAt = when;
      await progress.setHeartsRefillAt(when.millisecondsSinceEpoch);
      _startHeartsTimer();
    }
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
      wrongs.add(current!);
      if (hearts == 0) {
        final when = DateTime.now().add(const Duration(minutes: 10));
        heartsRefillAt = when;
        await progress.setHeartsRefillAt(when.millisecondsSinceEpoch);
        _startHeartsTimer();
      }
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
      _showSummary();
      pool = List.from(widget.phrases)..shuffle();
    }
    _nextQuestion();
  }

  void _startHeartsTimer() {
    heartsTimer?.cancel();
    if (heartsRefillAt == null) return;
    heartsTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      if (!mounted) return t.cancel();
      if (DateTime.now().isAfter(heartsRefillAt!)) {
        hearts = maxHearts;
        heartsRefillAt = null;
        await progress.clearHeartsRefill();
        setState(() {});
        t.cancel();
      } else {
        setState(() {});
      }
    });
  }

  void _showSummary() async {
    final latestXP = await progress.getDailyXP();
    final latestStreak = await progress.getStreak();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Lesson complete',
                    style: Theme.of(ctx).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),
            Text('Score: $correctCount / $answered'),
            const SizedBox(height: 4),
            Text('XP today: $latestXP'),
            const SizedBox(height: 4),
            Text('Streak: $latestStreak days'),
            const SizedBox(height: 12),
            if (wrongs.isNotEmpty) ...[
              const Text('Review mistakes'),
              const SizedBox(height: 6),
              SizedBox(
                height: min(200, 48.0 * wrongs.length + 8),
                child: ListView.builder(
                  itemCount: wrongs.length,
                  itemBuilder: (_, i) {
                    final p = wrongs[i];
                    return ListTile(
                      dense: true,
                      leading:
                          const Icon(Icons.error_outline, color: Colors.red),
                      title: Text(p.english),
                      subtitle:
                          Text(_valueFor(p, currentTargetLang ?? 'amharic')),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Continue'),
                ),
                const SizedBox(width: 8),
                if (wrongs.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      for (final p in wrongs) {
                        pool.insert(0, p);
                      }
                      wrongs.clear();
                      Navigator.pop(ctx);
                      _nextQuestion();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry mistakes'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    correctCount = 0;
    answered = 0;
    usedHint = false;
    hintLevel = 0;
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
                _exerciseLabel(currentExerciseType!),
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _exerciseColor(currentExerciseType!),
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
              label: Text(
                heartsRefillAt == null
                    ? '❤️ $hearts'
                    : '❤️ $hearts • ${_refillCountdown()}',
                style: const TextStyle(fontSize: 12),
              ),
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
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              final text =
                                  _valueFor(current!, currentTargetLang!);
                              final usedRemote = await TTSService().play(text,
                                  langCode: currentTargetLang,
                                  playbackRate: 1.0);
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
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final text =
                                  _valueFor(current!, currentTargetLang!);
                              final usedRemote = await TTSService().play(text,
                                  langCode: currentTargetLang,
                                  playbackRate: 0.8);
                              if (!usedRemote && mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Network issue — using fallback voice')),
                                );
                              }
                            },
                            icon: const Icon(Icons.slow_motion_video),
                            label: const Text('Play Slow'),
                          ),
                        ],
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
                : currentExerciseType == ExerciseType.typeAnswer
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('✍️ Type the answer'),
                          const SizedBox(height: 8),
                          Text(
                            current!.english,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Chip(
                                  label: Text('Target: ${currentTargetLang!}')),
                              const SizedBox(width: 8),
                              const Text(
                                  'Type the translation in the target language')
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _typeController,
                            autofocus: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) {
                              final target =
                                  _valueFor(current!, currentTargetLang!);
                              String norm(String s) => s
                                  .toLowerCase()
                                  .replaceAll(RegExp(r"\s+"), " ")
                                  .trim();
                              final ok =
                                  norm(_typeController.text) == norm(target);
                              _typeController.clear();
                              _onAnswer(ok);
                            },
                            decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                hintText: 'Type here in ${currentTargetLang!}'),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              final target =
                                  _valueFor(current!, currentTargetLang!);
                              String norm(String s) => s
                                  .toLowerCase()
                                  .replaceAll(RegExp(r"\s+"), " ")
                                  .trim();
                              final ok =
                                  norm(_typeController.text) == norm(target);
                              _typeController.clear();
                              _onAnswer(ok);
                            },
                            child: const Text('Submit'),
                          )
                        ],
                      )
                    : currentExerciseType == ExerciseType.tapComplete
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🧩 Tap to complete'),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _tapTokens()
                                    .map((t) => ChoiceChip(
                                          label: Text(t),
                                          selected: false,
                                          onSelected: (_) {
                                            setState(() {
                                              tapBuild = (tapBuild.isEmpty
                                                      ? t
                                                      : '$tapBuild $t')
                                                  .trim();
                                            });
                                          },
                                        ))
                                    .toList(),
                              ),
                              const SizedBox(height: 8),
                              Text('Current: $tapBuild'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      final target = _valueFor(
                                          current!, currentTargetLang!);
                                      final ok = tapBuild.trim() == target;
                                      tapBuild = '';
                                      _onAnswer(ok);
                                    },
                                    child: const Text('Submit'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        tapBuild = '';
                                      });
                                    },
                                    child: const Text('Clear'),
                                  )
                                ],
                              )
                            ],
                          )
                        : currentExerciseType == ExerciseType.matchPairs
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('🧠 Match pairs'),
                                  const SizedBox(height: 8),
                                  const Text(
                                      'Tap a left item, then its match on the right'),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          children: List.generate(
                                              matchLeft.length, (i) {
                                            final solved =
                                                matchSolved.contains(i);
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: ElevatedButton(
                                                onPressed: solved
                                                    ? null
                                                    : () {
                                                        setState(() {
                                                          matchSelL = i;
                                                        });
                                                      },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      matchSelL == i
                                                          ? Colors.teal.shade200
                                                          : null,
                                                ),
                                                child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(matchLeft[i])),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          children: List.generate(
                                              matchRight.length, (j) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  setState(() {
                                                    matchSelR = j;
                                                  });
                                                  if (matchSelL != null &&
                                                      matchSelR != null) {
                                                    final leftText =
                                                        matchLeft[matchSelL!];
                                                    final rightText =
                                                        matchRight[matchSelR!];
                                                    final idxL = matchSelL!;
                                                    final isMatch =
                                                        _valueForPhraseEnglish(
                                                                leftText) ==
                                                            rightText;
                                                    if (isMatch) {
                                                      matchSolved.add(idxL);
                                                      matchSelL = null;
                                                      matchSelR = null;
                                                      if (matchSolved.length ==
                                                          matchLeft.length) {
                                                        _onAnswer(true);
                                                      } else {
                                                        setState(() {});
                                                      }
                                                    } else {
                                                      matchSelL = null;
                                                      matchSelR = null;
                                                      _onAnswer(false);
                                                    }
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      matchSelR == j
                                                          ? Colors.teal.shade200
                                                          : null,
                                                ),
                                                child: Align(
                                                    alignment:
                                                        Alignment.centerLeft,
                                                    child: Text(matchRight[j])),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        onPressed: (matchSelL != null &&
                                                matchSelR != null)
                                            ? () {
                                                final leftText =
                                                    matchLeft[matchSelL!];
                                                final rightText =
                                                    matchRight[matchSelR!];
                                                final idxL = matchSelL!;
                                                final isMatch =
                                                    _valueForPhraseEnglish(
                                                            leftText) ==
                                                        rightText;
                                                if (isMatch) {
                                                  matchSolved.add(idxL);
                                                  matchSelL = null;
                                                  matchSelR = null;
                                                  if (matchSolved.length ==
                                                      matchLeft.length) {
                                                    _onAnswer(true);
                                                  } else {
                                                    setState(() {});
                                                  }
                                                } else {
                                                  matchSelL = null;
                                                  matchSelR = null;
                                                  _onAnswer(false);
                                                }
                                              }
                                            : null,
                                        child: const Text('Check'),
                                      ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            matchSelL = null;
                                            matchSelR = null;
                                          });
                                        },
                                        child: const Text('Clear'),
                                      )
                                    ],
                                  )
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
          label: Text('⭐ $dailyXP / $dailyGoal',
              style: const TextStyle(fontSize: 12)),
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

  List<String> _tapTokens() {
    final t = _valueFor(current!, currentTargetLang!);
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    parts.shuffle();
    return parts;
  }

  int _findMatchRightIndex(String right) {
    for (int j = 0; j < matchRight.length; j++) {
      if (matchRight[j] == right) return j;
    }
    return -1;
  }

  String _valueForPhraseEnglish(String english) {
    final p = widget.phrases
        .firstWhere((x) => x.english == english, orElse: () => current!);
    return _valueFor(p, currentTargetLang!);
  }

  String _refillCountdown() {
    if (heartsRefillAt == null) return '';
    final d = heartsRefillAt!.difference(DateTime.now());
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  String _exerciseLabel(ExerciseType t) {
    switch (t) {
      case ExerciseType.multipleChoice:
        return '📝 Multiple Choice';
      case ExerciseType.speech:
        return '🎤 Speech';
      case ExerciseType.listening:
        return '🔊 Listening';
      case ExerciseType.typeAnswer:
        return '✍️ Type Answer';
      case ExerciseType.tapComplete:
        return '🧩 Tap Complete';
      case ExerciseType.matchPairs:
        return '🧠 Match Pairs';
    }
  }

  Color _exerciseColor(ExerciseType t) {
    switch (t) {
      case ExerciseType.multipleChoice:
        return Colors.blue.shade100;
      case ExerciseType.speech:
        return Colors.teal.shade100;
      case ExerciseType.listening:
        return Colors.indigo.shade100;
      case ExerciseType.typeAnswer:
        return Colors.purple.shade100;
      case ExerciseType.tapComplete:
        return Colors.amber.shade100;
      case ExerciseType.matchPairs:
        return Colors.green.shade100;
    }
  }

  @override
  void dispose() {
    bonusTimer?.cancel();
    heartsTimer?.cancel();
    super.dispose();
  }
}