// lib/widgets/phrase_card.dart
import 'package:flutter/material.dart';
import '../models/phrase.dart';

class PhraseCard extends StatelessWidget {
  final Phrase phrase;
  final VoidCallback? onTap;
  final List<String> visibleLanguages;

  const PhraseCard({
    required this.phrase,
    this.onTap,
    this.visibleLanguages = const ["Amharic", "Oromo", "Tigrinya"],
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.orange.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.deepOrange.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                phrase.category,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange.shade800,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // English phrase
            Text(
              phrase.english,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
    color: Color(0xFF3E2723),  // This is the hex value for brown.shade900
              ),
            ),
            const SizedBox(height: 16),

            // Translations (only visible languages)
            ...visibleLanguages.map((lang) {
              final text = lang == "Amharic"
                  ? phrase.amharic
                  : lang == "Oromo"
                      ? phrase.oromo
                      : phrase.tigrinya;

              if (text.isEmpty) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        "$lang:",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.brown.shade700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontSize: 17,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}