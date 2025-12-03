import 'package:flutter/material.dart';

typedef OnAnswer = void Function(bool correct);

class MultipleChoice extends StatelessWidget {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final OnAnswer onAnswer;

  const MultipleChoice({
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.onAnswer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(prompt, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        ...List.generate(options.length, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: ElevatedButton(
              onPressed: () {
                final correct = i == correctIndex;
                onAnswer(correct);
              },
              child: Text(options[i]),
            ),
          );
        }),
      ],
    );
  }
}
