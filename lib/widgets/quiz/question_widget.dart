import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';
import 'multiple_choice_widget.dart';
import 'fill_blank_widget.dart';
import 'image_question_widget.dart';
import 'listen_select_widget.dart';
import 'select_image_widget.dart';
import 'matching_pairs_widget.dart';
import 'sentence_completion_widget.dart';

typedef OnAnswer = void Function(bool correct);

class QuestionWidget extends StatelessWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    switch (question.type) {
      case QuizQuestionType.multipleChoice:
      case QuizQuestionType.translate:
        return MultipleChoiceWidget(
          question: question,
          onAnswer: onAnswer,
        );

      case QuizQuestionType.fillInTheBlank:
        return FillBlankWidget(
          question: question,
          onAnswer: onAnswer,
        );

      case QuizQuestionType.imageQuestion:
        return ImageQuestionWidget(
          question: question,
          onAnswer: onAnswer,
        );

      case QuizQuestionType.listenAndSelect:
        return ListenSelectWidget(
          question: question,
          onAnswer: onAnswer,
        );

      case QuizQuestionType.selectImageFromWord:
        return SelectImageWidget(
          question: question,
          onAnswer: onAnswer,
        );

      case QuizQuestionType.matchWords:
        return MatchingPairsWidget(
          question: question,
          onAnswer: onAnswer,
        );

      case QuizQuestionType.completeSentence:
        return SentenceCompletionWidget(
          question: question,
          onAnswer: onAnswer,
        );

      default:
        return Center(
          child: Text('Question type not implemented: ${question.type}'),
        );
    }
  }
}
