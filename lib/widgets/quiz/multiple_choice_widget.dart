import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

typedef OnAnswer = void Function(bool correct);

class MultipleChoiceWidget extends StatefulWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const MultipleChoiceWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<MultipleChoiceWidget> createState() => _MultipleChoiceWidgetState();
}

class _MultipleChoiceWidgetState extends State<MultipleChoiceWidget> {
  int? selectedIndex;
  bool showResult = false;

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options ?? [];
    final correctIndex = widget.question.correctIndex ?? 0;

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

        // Options
        ...List.generate(options.length, (index) {
          final isSelected = selectedIndex == index;
          final isCorrect = index == correctIndex;
          final isWrong = isSelected && !isCorrect;

          Color? backgroundColor;
          if (showResult) {
            if (isCorrect) {
              backgroundColor = Colors.green.shade100;
            } else if (isWrong) {
              backgroundColor = Colors.red.shade100;
            }
          } else {
            backgroundColor = isSelected ? Colors.blue.shade50 : Colors.white;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: showResult ? null : () => _selectOption(index),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: showResult
                        ? (isCorrect
                            ? Colors.green
                            : isWrong
                                ? Colors.red
                                : Colors.grey.shade300)
                        : isSelected
                            ? Colors.blue
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
                child: Row(
                  children: [
                    // Option letter
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: showResult
                            ? (isCorrect
                                ? Colors.green
                                : isWrong
                                    ? Colors.red
                                    : Colors.grey.shade300)
                            : isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          String.fromCharCode(65 + index), // A, B, C, D
                          style: TextStyle(
                            color: showResult
                                ? (isCorrect || isWrong
                                    ? Colors.white
                                    : Colors.black54)
                                : isSelected
                                    ? Colors.white
                                    : Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Option text
                    Expanded(
                      child: Text(
                        options[index],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    // Result icon
                    if (showResult && (isCorrect || isWrong))
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),

        // Continue button
        if (showResult)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: ElevatedButton(
              onPressed: () {
                widget.onAnswer(selectedIndex == correctIndex);
                // Reset for next question
                setState(() {
                  selectedIndex = null;
                  showResult = false;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Continue',
                style: TextStyle(
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

  void _selectOption(int index) {
    setState(() {
      selectedIndex = index;
    });

    // Show result after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          showResult = true;
        });
      }
    });
  }
}
