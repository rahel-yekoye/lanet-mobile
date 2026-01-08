import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';
import 'multiple_choice_widget.dart';

typedef OnAnswer = void Function(bool correct);

// Translate questions use the same UI as multiple choice
class TranslateWidget extends StatelessWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const TranslateWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    // Translate questions are essentially multiple choice with different wording
    return MultipleChoiceWidget(
      question: question,
      onAnswer: onAnswer,
    );
  }
}
