import 'package:flutter/material.dart';
import '../../models/quiz_question.dart';

typedef OnAnswer = void Function(bool correct);

class MatchingPairsWidget extends StatefulWidget {
  final QuizQuestion question;
  final OnAnswer onAnswer;

  const MatchingPairsWidget({
    super.key,
    required this.question,
    required this.onAnswer,
  });

  @override
  State<MatchingPairsWidget> createState() => _MatchingPairsWidgetState();
}

class _MatchingPairsWidgetState extends State<MatchingPairsWidget> {
  Map<String, String?> selectedPairs = {}; // source -> target
  String? firstSelected;
  bool showResult = false;
  List<Map<String, String>> correctPairs = [];

  @override
  void initState() {
    super.initState();
    correctPairs = widget.question.matchingPairs ?? [];
    // Initialize selected pairs
    for (final pair in correctPairs) {
      selectedPairs[pair.keys.first] = null;
    }
  }

  void _selectItem(String item, bool isSource) {
    if (showResult) return;

    setState(() {
      if (isSource) {
        if (firstSelected == item) {
          firstSelected = null;
        } else {
          firstSelected = item;
        }
      } else {
        if (firstSelected != null) {
          selectedPairs[firstSelected!] = item;
          firstSelected = null;
          _checkCompletion();
        }
      }
    });
  }

  void _checkCompletion() {
    bool allMatched = true;
    for (final pair in correctPairs) {
      final source = pair.keys.first;
      final target = pair.values.first;
      if (selectedPairs[source] != target) {
        allMatched = false;
        break;
      }
    }

    if (allMatched && selectedPairs.values.every((v) => v != null)) {
      setState(() {
        showResult = true;
      });
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          widget.onAnswer(true);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pairs = widget.question.matchingPairs ?? [];
    final sources = pairs.map((p) => p.keys.first).toList();
    final targets = pairs.map((p) => p.values.first).toList()..shuffle();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Tap matching pairs',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Source words (left side)
        const Text(
          'Source',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: sources.length,
            itemBuilder: (context, index) {
              final source = sources[index];
              final isSelected = firstSelected == source;
              final matchedTarget = selectedPairs[source];
              final isCorrect = matchedTarget != null &&
                  correctPairs.any((p) =>
                      p.keys.first == source && p.values.first == matchedTarget);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: matchedTarget == null
                      ? () => _selectItem(source, true)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? Colors.green.shade100
                          : isSelected
                              ? Colors.blue.shade100
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCorrect
                            ? Colors.green
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
                            source,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (matchedTarget != null)
                          Row(
                            children: [
                              const Icon(Icons.arrow_forward, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                matchedTarget,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 24),
        const Divider(),

        // Target words (right side)
        const Text(
          'Match with',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final target = targets[index];
              final isUsed = selectedPairs.values.contains(target);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: firstSelected != null && !isUsed
                      ? () => _selectItem(target, false)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isUsed
                          ? Colors.grey.shade200
                          : firstSelected != null
                              ? Colors.yellow.shade100
                              : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUsed
                            ? Colors.grey.shade400
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      target,
                      style: TextStyle(
                        fontSize: 18,
                        color: isUsed
                            ? Colors.grey.shade500
                            : Colors.black87,
                      ),
                    ),
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
