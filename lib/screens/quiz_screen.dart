import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../models/quiz_question.dart';
import '../widgets/quiz/question_widget.dart';
import '../services/srs_service.dart';
import 'dart:math';

class QuizScreen extends StatefulWidget {
  final String category;
  final List<QuizQuestion> questions;
  final String targetLanguage;

  const QuizScreen({
    super.key,
    required this.category,
    required this.questions,
    this.targetLanguage = 'amharic',
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int currentQuestionIndex = 0;
  int correctAnswers = 0;
  int wrongAnswers = 0;
  final SRSService _srs = SRSService();
  late ConfettiController _confettiController;
  bool _showCompletion = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  QuizQuestion? get currentQuestion {
    if (currentQuestionIndex >= widget.questions.length) return null;
    return widget.questions[currentQuestionIndex];
  }

  double get progress {
    if (widget.questions.isEmpty) return 0.0;
    return (currentQuestionIndex + 1) / widget.questions.length;
  }

  void _handleAnswer(bool correct) async {
    if (correct) {
      setState(() {
        correctAnswers++;
      });
      // Mark correct in SRS
      final question = currentQuestion;
      if (question != null && question.englishText != null) {
        await _srs.markCorrect(widget.category, question.englishText!);
      }
    } else {
      setState(() {
        wrongAnswers++;
      });
      // Mark wrong in SRS
      final question = currentQuestion;
      if (question != null && question.englishText != null) {
        await _srs.markWrong(widget.category, question.englishText!);
      }
    }

    // Move to next question
    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      if (currentQuestionIndex < widget.questions.length - 1) {
        setState(() {
          currentQuestionIndex++;
        });
      } else {
        // Quiz completed
        _confettiController.play();
        setState(() {
          _showCompletion = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showCompletion) {
      return _buildCompletionScreen();
    }

    if (currentQuestion == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.category)),
        body: const Center(child: Text('No questions available')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.category),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$correctAnswers',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Icon(Icons.cancel, color: Colors.red, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$wrongAnswers',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Progress bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Question ${currentQuestionIndex + 1} of ${widget.questions.length}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Question content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: QuestionWidget(
                    question: currentQuestion!,
                    onAnswer: _handleAnswer,
                  ),
                ),
              ),
            ],
          ),

          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionScreen() {
    final accuracy = widget.questions.isEmpty
        ? 0.0
        : (correctAnswers / widget.questions.length) * 100;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Completion icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.celebration,
                  size: 60,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'Quiz Completed!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 16),
              
              // Stats
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      'Correct Answers',
                      '$correctAnswers',
                      Colors.green,
                      Icons.check_circle,
                    ),
                    const Divider(height: 32),
                    _buildStatRow(
                      'Wrong Answers',
                      '$wrongAnswers',
                      Colors.red,
                      Icons.cancel,
                    ),
                    const Divider(height: 32),
                    _buildStatRow(
                      'Accuracy',
                      '${accuracy.toStringAsFixed(1)}%',
                      Colors.blue,
                      Icons.analytics,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Back to Course',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
