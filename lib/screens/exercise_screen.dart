import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../services/exercise_service.dart';
import '../services/progress_service.dart';
import '../widgets/celebration_dialog.dart';
import 'dart:math';

class ExerciseScreen extends StatefulWidget {
  final String lessonId;
  final String lessonTitle;
  final List<Exercise> exercises;
  final VoidCallback? onComplete;

  const ExerciseScreen({
    super.key,
    required this.lessonId,
    required this.lessonTitle,
    required this.exercises,
    this.onComplete,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int _currentExerciseIndex = 0;
  int _totalXpEarned = 0;
  int _correctAnswers = 0;
  final ProgressService _progress = ProgressService();
  final Random _random = Random();
  String? _selectedAnswer;
  bool _showResult = false;
  bool _isCorrect = false;
  List<String> _shuffledOptions = [];

  @override
  void initState() {
    super.initState();
    _shuffleOptions();
  }

  void _shuffleOptions() {
    final exercise = widget.exercises[_currentExerciseIndex];
    if (exercise.type == 'multiple-choice' && exercise.options != null) {
      final options = List<String>.from(exercise.options!['options'] as List);
      options.shuffle(_random);
      setState(() {
        _shuffledOptions = options;
        _selectedAnswer = null;
        _showResult = false;
      });
    }
  }

  Exercise get _currentExercise => widget.exercises[_currentExerciseIndex];
  bool get _isLastExercise => _currentExerciseIndex >= widget.exercises.length - 1;

  Future<void> _submitAnswer(String? answer) async {
    if (answer == null) return;

    setState(() {
      _selectedAnswer = answer;
      _isCorrect = answer == _currentExercise.correctAnswer;
      _showResult = true;
    });

    if (_isCorrect) {
      _correctAnswers++;
      final pointsEarned = _currentExercise.points;
      _totalXpEarned += pointsEarned;

      // Award XP
      await _progress.addXP(pointsEarned);

      // Save progress
      await ExerciseService.saveExerciseProgress(
        exerciseId: _currentExercise.id,
        lessonId: widget.lessonId,
        isCorrect: true,
        pointsEarned: pointsEarned,
      );
    } else {
      await ExerciseService.saveExerciseProgress(
        exerciseId: _currentExercise.id,
        lessonId: widget.lessonId,
        isCorrect: false,
        pointsEarned: 0,
      );
    }

    // Wait a moment to show result
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (_isLastExercise) {
      // All exercises completed
      await _completeLesson();
    } else {
      // Move to next exercise
      setState(() {
        _currentExerciseIndex++;
        _showResult = false;
        _selectedAnswer = null;
      });
      _shuffleOptions();
    }
  }

  Future<void> _completeLesson() async {
    // Mark lesson as completed
    await ExerciseService.markLessonCompleted(widget.lessonId, _totalXpEarned);

    // Check for achievements
    final unlockedBadges = await _progress.checkAndUnlockAchievements();
    await _progress.bumpStreakIfFirstSuccessToday();

    if (!mounted) return;

    // Show celebration dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CelebrationDialog(
        xpEarned: _totalXpEarned,
        achievements: unlockedBadges,
        nextCategory: null,
        onContinue: () {
          Navigator.of(context).pop(); // Pop exercise screen
          widget.onComplete?.call();
        },
      ),
    );
  }

  Widget _buildExercise() {
    switch (_currentExercise.type) {
      case 'multiple-choice':
        return _buildMultipleChoice();
      case 'translate':
        return _buildTranslate();
      case 'fill-blank':
        return _buildFillBlank();
      case 'matching':
        return _buildMatching();
      case 'reorder':
        return _buildReorder();
      case 'listen-repeat':
        return _buildListenRepeat();
      default:
        return _buildMultipleChoice();
    }
  }

  Widget _buildMultipleChoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentExercise.prompt,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 24),
        ..._shuffledOptions.map((option) {
          final isSelected = _selectedAnswer == option;
          final isCorrectOption = option == _currentExercise.correctAnswer;
          Color? backgroundColor;
          Color? textColor;

          if (_showResult) {
            if (isCorrectOption) {
              backgroundColor = Colors.green.shade100;
              textColor = Colors.green.shade900;
            } else if (isSelected && !isCorrectOption) {
              backgroundColor = Colors.red.shade100;
              textColor = Colors.red.shade900;
            } else {
              backgroundColor = Colors.grey.shade100;
              textColor = Colors.grey.shade700;
            }
          } else {
            backgroundColor = isSelected ? Colors.blue.shade100 : Colors.white;
            textColor = isSelected ? Colors.blue.shade900 : Colors.black87;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showResult ? null : () => _submitAnswer(option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (_showResult && isCorrectOption)
                        Icon(Icons.check_circle, color: Colors.green.shade700, size: 24)
                      else if (_showResult && isSelected && !isCorrectOption)
                        Icon(Icons.cancel, color: Colors.red.shade700, size: 24)
                      else
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          option,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTranslate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentExercise.prompt,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => _submitAnswer(value.trim()),
        ),
        const SizedBox(height: 16),
        if (_showResult)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isCorrect ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _isCorrect
                  ? 'Correct! ✅'
                  : 'Incorrect. The correct answer is: ${_currentExercise.correctAnswer}',
              style: TextStyle(
                color: _isCorrect ? Colors.green.shade900 : Colors.red.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFillBlank() {
    // Parse the sentence with blank markers (e.g., "Hello ___, how are you?")
    final prompt = _currentExercise.prompt;
    final parts = prompt.split('___');
    final blankIndex = prompt.indexOf('___');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fill in the blank',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (parts.isNotEmpty) ...[
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                    children: [
                      TextSpan(text: parts[0]),
                      WidgetSpan(
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _showResult
                                  ? (_isCorrect
                                      ? Colors.green
                                      : Colors.red)
                                  : Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _selectedAnswer ?? '___',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _showResult
                                  ? (_isCorrect
                                      ? Colors.green.shade700
                                      : Colors.red.shade700)
                                  : Colors.blue.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      if (parts.length > 1) TextSpan(text: parts[1]),
                    ],
                  ),
                ),
              ] else
                Text(
                  prompt,
                  style: const TextStyle(fontSize: 24),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (!_showResult)
          TextField(
            decoration: InputDecoration(
              hintText: 'Type the missing word...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
            onSubmitted: (value) => _submitAnswer(value.trim()),
            onChanged: (value) {
              setState(() {
                _selectedAnswer = value.trim();
              });
            },
          ),
        if (_showResult)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCorrect ? Colors.green.shade200 : Colors.red.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.cancel,
                  color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isCorrect
                        ? 'Correct! ✅'
                        : 'Incorrect. The correct answer is: ${_currentExercise.correctAnswer}',
                    style: TextStyle(
                      color: _isCorrect
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildMatching() {
    // Parse matching pairs from options
    final options = _currentExercise.options;
    if (options == null) {
      return const Center(child: Text('Invalid matching exercise'));
    }

    final leftItems = (options['left'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final rightItems = (options['right'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    // Shuffle right items for matching
    final shuffledRight = List<String>.from(rightItems)..shuffle(_random);
    int? selectedLeft;
    int? selectedRight;
    Map<int, int> matches = {}; // leftIndex -> rightIndex

    return StatefulBuilder(
      builder: (context, setState) {
        void handleLeftTap(int index) {
          if (matches.containsKey(index)) return; // Already matched
          setState(() {
            if (selectedLeft == index) {
              selectedLeft = null;
            } else {
              selectedLeft = index;
              if (selectedRight != null) {
                // Check if match is correct
                final correctRightIndex = rightItems.indexOf(leftItems[index]);
                if (selectedRight == shuffledRight.indexOf(rightItems[correctRightIndex])) {
                  matches[index] = selectedRight!;
                  // Check if all matched
                  if (matches.length == leftItems.length) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _submitAnswer('matched');
                    });
                  }
                } else {
                  // Wrong match - show error briefly
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    if (mounted) {
                      setState(() {
                        selectedLeft = null;
                        selectedRight = null;
                      });
                    }
                  });
                }
                selectedLeft = null;
                selectedRight = null;
              }
            }
          });
        }

        void handleRightTap(int index) {
          if (matches.values.contains(index)) return; // Already matched
          setState(() {
            if (selectedRight == index) {
              selectedRight = null;
            } else {
              selectedRight = index;
              if (selectedLeft != null) {
                // Check if match is correct
                final correctRightIndex = rightItems.indexOf(leftItems[selectedLeft!]);
                if (index == shuffledRight.indexOf(rightItems[correctRightIndex])) {
                  matches[selectedLeft!] = index;
                  // Check if all matched
                  if (matches.length == leftItems.length) {
                    Future.delayed(const Duration(milliseconds: 500), () {
                      _submitAnswer('matched');
                    });
                  }
                } else {
                  // Wrong match
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    if (mounted) {
                      setState(() {
                        selectedLeft = null;
                        selectedRight = null;
                      });
                    }
                  });
                }
                selectedLeft = null;
                selectedRight = null;
              }
            }
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentExercise.prompt,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Match the words on the left with their translations',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  child: Column(
                    children: leftItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isMatched = matches.containsKey(index);
                      final isSelected = selectedLeft == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isMatched ? null : () => handleLeftTap(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? Colors.green.shade100
                                    : isSelected
                                        ? Colors.blue.shade100
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMatched
                                      ? Colors.green
                                      : isSelected
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                  width: isMatched || isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  if (isMatched)
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700, size: 20),
                                  if (isMatched) const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isMatched
                                            ? Colors.green.shade900
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 16),
                // Right column
                Expanded(
                  child: Column(
                    children: shuffledRight.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isMatched = matches.values.contains(index);
                      final isSelected = selectedRight == index;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: isMatched ? null : () => handleRightTap(index),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? Colors.green.shade100
                                    : isSelected
                                        ? Colors.orange.shade100
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isMatched
                                      ? Colors.green
                                      : isSelected
                                          ? Colors.orange
                                          : Colors.grey.shade300,
                                  width: isMatched || isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isMatched
                                            ? Colors.green.shade900
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  if (isMatched) ...[
                                    const SizedBox(width: 8),
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700, size: 20),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildReorder() {
    return const Center(child: Text('Reorder exercise - Coming soon!'));
  }

  Widget _buildListenRepeat() {
    return const Center(child: Text('Listen and repeat exercise - Coming soon!'));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.exercises.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.lessonTitle)),
        body: const Center(
          child: Text('No exercises available for this lesson.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_totalXpEarned XP',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentExerciseIndex + 1) / widget.exercises.length,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentExerciseIndex + 1}/${widget.exercises.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Exercise content
            Expanded(
              child: SingleChildScrollView(
                child: _buildExercise(),
              ),
            ),
            if (_showResult && _isCorrect)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      '+${_currentExercise.points} XP',
                      style: TextStyle(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

