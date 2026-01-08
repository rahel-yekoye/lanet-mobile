import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

typedef OnAnswer = void Function(bool correct);

class ImageQuestionWidget extends StatefulWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const ImageQuestionWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<ImageQuestionWidget> createState() => _ImageQuestionWidgetState();
}

class _ImageQuestionWidgetState extends State<ImageQuestionWidget> {
  final TextEditingController _controller = TextEditingController();
  bool showResult = false;
  bool isCorrect = false;
  int? selectedIndex;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For image questions, we'll use multiple choice with image
    // If options are available, show them, otherwise show text input
    final hasOptions = widget.question.options != null && 
                      widget.question.options!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Question text
        Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            widget.question.questionText ?? 'What do you see in the image?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
            textAlign: TextAlign.center,
          ),
        ),

        // Image
        Container(
          height: 250,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: widget.question.imagePath != null
                ? Image.asset(
                    widget.question.imagePath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholderImage();
                    },
                  )
                : _buildPlaceholderImage(),
          ),
        ),

        // Options or text input
        if (hasOptions) _buildOptionsView() else _buildTextInputView(),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    // Create a colorful placeholder based on category
    final categoryColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
    ];
    final color = categoryColors[
        widget.question.category.hashCode % categoryColors.length];

    return Container(
      color: color.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 80,
            color: color.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            widget.question.category,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.question.englishText ?? '',
            style: TextStyle(
              fontSize: 16,
              color: color.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsView() {
    final options = widget.question.options ?? [];
    final correctIndex = widget.question.correctIndex ?? 0;

    return Column(
      children: [
        ...List.generate(options.length, (index) {
          final isSelected = selectedIndex == index;
          final isCorrectOption = index == correctIndex;
          final isWrong = isSelected && !isCorrectOption;

          Color? backgroundColor;
          if (showResult) {
            if (isCorrectOption) {
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
                        ? (isCorrectOption
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
                    if (showResult && (isCorrectOption || isWrong))
                      Icon(
                        isCorrectOption ? Icons.check_circle : Icons.cancel,
                        color: isCorrectOption ? Colors.green : Colors.red,
                        size: 28,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
        if (showResult)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ElevatedButton(
              onPressed: () {
                widget.onAnswer(isCorrect);
                setState(() {
                  selectedIndex = null;
                  showResult = false;
                  isCorrect = false;
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

  Widget _buildTextInputView() {
    return Column(
      children: [
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
          ),
          child: TextField(
            controller: _controller,
            enabled: !showResult,
            decoration: InputDecoration(
              hintText: 'What do you see?',
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
            onSubmitted: showResult ? null : _checkAnswer,
          ),
        ),
        if (showResult && !isCorrect)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Correct answer: ${widget.question.correctAnswer}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
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
              backgroundColor: Colors.blue,
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

  void _selectOption(int index) {
    setState(() {
      selectedIndex = index;
      final correctIndex = widget.question.correctIndex ?? 0;
      isCorrect = index == correctIndex;
      showResult = true;
    });

    // Auto-continue after showing result
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted && showResult) {
        widget.onAnswer(isCorrect);
        setState(() {
          selectedIndex = null;
          showResult = false;
          isCorrect = false;
        });
      }
    });
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
