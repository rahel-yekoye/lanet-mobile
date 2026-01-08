import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/quiz_question.dart';

typedef OnAnswer = void Function(bool correct);

class ListenSelectWidget extends StatefulWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const ListenSelectWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<ListenSelectWidget> createState() => _ListenSelectWidgetState();
}

class _ListenSelectWidgetState extends State<ListenSelectWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int? selectedIndex;
  bool showResult = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (widget.question.audioPath == null) return;

    setState(() => _isPlaying = true);
    try {
      await _audioPlayer.play(AssetSource(widget.question.audioPath!));
      await _audioPlayer.onPlayerComplete.first;
      setState(() => _isPlaying = false);
    } catch (e) {
      setState(() => _isPlaying = false);
      // Fallback: show text if audio fails
    }
  }

  void _selectOption(int index) {
    if (showResult) return;

    setState(() {
      selectedIndex = index;
    });

    final correctIndex = widget.question.correctIndex ?? 0;
    final isCorrect = index == correctIndex;

    // Show result after delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          showResult = true;
        });
        // Auto continue
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            widget.onAnswer(isCorrect);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.question.options ?? [];
    final correctIndex = widget.question.correctIndex ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Play audio button
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: _isPlaying ? null : _playAudio,
              icon: Icon(
                _isPlaying ? Icons.volume_up : Icons.play_circle_filled,
                size: 60,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tap what you hear',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 32),

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
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        options[index],
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
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
      ],
    );
  }
}
