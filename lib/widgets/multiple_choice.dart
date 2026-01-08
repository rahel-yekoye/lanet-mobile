import 'package:flutter/material.dart';

typedef OnAnswer = void Function(bool correct);

class MultipleChoice extends StatefulWidget {
  final String prompt;
  final List<String> options;
  final int correctIndex;
  final OnAnswer onAnswer;

  const MultipleChoice({
    super.key,
    required this.prompt,
    required this.options,
    required this.correctIndex,
    required this.onAnswer,
  });

  @override
  State<MultipleChoice> createState() => _MultipleChoiceState();
}

class _MultipleChoiceState extends State<MultipleChoice> {
  int? _selected;
  bool _locked = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.prompt,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...List.generate(widget.options.length, (i) {
          final isCorrect = i == widget.correctIndex;
          final isSelected = _selected == i;
          Color? bg;
          Color? fg;
          Widget? icon;
          if (_locked) {
            if (isCorrect) {
              bg = Colors.green.shade100;
              fg = Colors.green.shade900;
              icon = const Icon(Icons.check, color: Colors.green);
            } else if (isSelected) {
              bg = Colors.red.shade100;
              fg = Colors.red.shade900;
              icon = const Icon(Icons.close, color: Colors.red);
            }
          }
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: ElevatedButton(
              onPressed: _locked
                  ? null
                  : () async {
                      setState(() {
                        _selected = i;
                        _locked = true;
                      });
                      final correct = i == widget.correctIndex;
                      await Future.delayed(const Duration(milliseconds: 450));
                      widget.onAnswer(correct);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
              ),
              child: Row(
                children: [
                  if (icon != null) ...[icon, const SizedBox(width: 8)],
                  Expanded(child: Text(widget.options[i])),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}