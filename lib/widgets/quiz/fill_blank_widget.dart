import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

typedef OnAnswer = void Function(bool correct);

class FillBlankWidget extends StatefulWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const FillBlankWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<FillBlankWidget> createState() => _FillBlankWidgetState();
}

class _FillBlankWidgetState extends State<FillBlankWidget> {
  final TextEditingController _controller = TextEditingController();
  bool showResult = false;
  bool isCorrect = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question text
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.only(bottom: 24),
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
          child: Text(
            widget.question.questionText ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Input field
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: showResult
                  ? (isCorrect ? Colors.green : Colors.red)
                  : Colors.grey.shade300,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            enabled: !showResult,
            decoration: InputDecoration(
              hintText: 'Type your answer here...',
              border: InputBorder.none,
              suffixIcon: showResult
                  ? Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: isCorrect ? Colors.green : Colors.red,
                      size: 28,
                    )
                  : null,
            ),
            style: const TextStyle(
              fontSize: 18,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            onSubmitted: showResult ? null : _checkAnswer,
          ),
        ),

        // Correct answer display (if wrong)
        if (showResult && !isCorrect)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Correct answer: ${widget.question.correctAnswer}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Submit/Continue button
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: ElevatedButton(
            onPressed: showResult
                ? () {
                    widget.onAnswer(isCorrect);
                    setState(() {
                      _controller.clear();
                      showResult = false;
                      isCorrect = false;
                    });
                  }
                : _checkAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: showResult
                  ? (isCorrect ? Colors.green : Colors.blue)
                  : Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              showResult ? 'Continue' : 'Submit',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _checkAnswer([String? _]) {
    final userAnswer = _controller.text.trim().toLowerCase();
    final correctAnswer = widget.question.correctAnswer.toLowerCase();

    setState(() {
      isCorrect = userAnswer == correctAnswer;
      showResult = true;
    });
  }
}
