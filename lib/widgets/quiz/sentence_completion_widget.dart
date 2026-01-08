import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

typedef OnAnswer = void Function(bool correct);

class SentenceCompletionWidget extends StatefulWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const SentenceCompletionWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<SentenceCompletionWidget> createState() =>
      _SentenceCompletionWidgetState();
}

class _SentenceCompletionWidgetState
    extends State<SentenceCompletionWidget> {
  List<String> selectedWords = [];
  List<String> availableWords = [];
  String sentenceTemplate = '';
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    availableWords = List.from(widget.question.sentenceWords ?? [])..shuffle();
    sentenceTemplate = widget.question.questionText ?? '';
  }

  void _selectWord(String word) {
    if (showResult) return;

    setState(() {
      selectedWords.add(word);
      availableWords.remove(word);
      _checkCompletion();
    });
  }

  void _removeWord(int index) {
    if (showResult) return;

    setState(() {
      final word = selectedWords.removeAt(index);
      availableWords.add(word);
    });
  }

  void _checkCompletion() {
    // Check if sentence matches correct answer
    final userSentence = selectedWords.join(' ');
    final correctAnswer = widget.question.correctAnswer.toLowerCase().trim();
    final isCorrect = userSentence.toLowerCase().trim() == correctAnswer;

    // Allow some flexibility in word order for now
    if (selectedWords.length == (widget.question.sentenceWords ?? []).length) {
      setState(() {
        showResult = true;
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          widget.onAnswer(isCorrect);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sentence template
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
              Text(
                sentenceTemplate,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Selected words display
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...selectedWords.asMap().entries.map((entry) {
                    return Chip(
                      label: Text(entry.value),
                      onDeleted: showResult
                          ? null
                          : () => _removeWord(entry.key),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      backgroundColor: Colors.blue.shade100,
                    );
                  }),
                  if (selectedWords.length < availableWords.length + selectedWords.length)
                    Container(
                      width: 100,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Complete the sentence from the words below:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 16),

        // Available words
        Expanded(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: availableWords.map((word) {
              return InkWell(
                onTap: () => _selectWord(word),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    word,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        if (showResult)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Correct!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
