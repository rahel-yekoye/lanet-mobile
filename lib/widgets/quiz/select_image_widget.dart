import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/quiz_question.dart';

typedef OnAnswer = void Function(bool correct);

class SelectImageWidget extends StatefulWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const SelectImageWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<SelectImageWidget> createState() => _SelectImageWidgetState();
}

class _SelectImageWidgetState extends State<SelectImageWidget> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int? selectedIndex;
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    // Auto-play audio when question loads
    Future.delayed(const Duration(milliseconds: 500), _playAudio);
  }

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
    }
  }

  void _selectImage(int index) {
    if (showResult) return;

    setState(() {
      selectedIndex = index;
    });

    final correctIndex = widget.question.correctIndex ?? 0;
    final isCorrect = index == correctIndex;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          showResult = true;
        });
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
    final imageOptions = widget.question.imageOptions ?? [];
    final correctIndex = widget.question.correctIndex ?? 0;
    final word = widget.question.questionText ?? widget.question.englishText ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Word text with audio button
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
                word,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              IconButton(
                onPressed: _isPlaying ? null : _playAudio,
                icon: Icon(
                  _isPlaying ? Icons.volume_up : Icons.volume_up_outlined,
                  size: 32,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Select the correct image',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 24),

        // Image grid
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: imageOptions.length,
            itemBuilder: (context, index) {
              final isSelected = selectedIndex == index;
              final isCorrect = index == correctIndex;
              final isWrong = isSelected && !isCorrect;

              Color? borderColor;
              if (showResult) {
                borderColor = isCorrect
                    ? Colors.green
                    : isWrong
                        ? Colors.red
                        : Colors.grey.shade300;
              } else {
                borderColor = isSelected ? Colors.blue : Colors.grey.shade300;
              }

              return InkWell(
                onTap: showResult ? null : () => _selectImage(index),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: borderColor,
                      width: showResult && (isCorrect || isWrong) ? 3 : 2,
                    ),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          imageOptions[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      if (showResult)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isCorrect ? Colors.green : Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCorrect ? Icons.check : Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
