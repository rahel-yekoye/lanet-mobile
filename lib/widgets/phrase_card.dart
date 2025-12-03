import 'package:flutter/material.dart';
import '../models/phrase.dart';

class PhraseCard extends StatelessWidget {
  final Phrase phrase;
  final VoidCallback? onTap;
  final List<String> visibleLanguages; // ✅ Add this


  const PhraseCard({
    required this.phrase,
    this.onTap,
    this.visibleLanguages = const ["Amharic", "Oromo", "Tigrinya"], // default

    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.teal.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                phrase.category,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.teal.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              phrase.english,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildTranslationRow("Amharic", phrase.amharic),
            const SizedBox(height: 4),
            _buildTranslationRow("Oromo", phrase.oromo),
            const SizedBox(height: 4),
            _buildTranslationRow("Tigrinya", phrase.tigrinya),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationRow(String lang, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$lang:",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
