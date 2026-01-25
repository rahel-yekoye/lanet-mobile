import 'package:flutter/material.dart';
import 'package:lanet_mobile/models/fidel_model.dart';
import 'package:lanet_mobile/services/alphabet_audio_service.dart';

class FidelTile extends StatelessWidget {
  final FidelModel fidel;
  final VoidCallback onTap;
  final bool showLabel;

  const FidelTile({
    super.key, // ✅ important
    required this.fidel,
    required this.onTap,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final audioService = AlphabetAudioService();
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // Play audio when alphabet is clicked
          await audioService.playAlphabetAudio(fidel.character);
          // Then execute the original onTap callback (navigation) if provided
          // This allows family tiles to navigate while individual letters only play audio
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.orange.shade50,
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                fidel.character,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (showLabel) ...[
                const SizedBox(height: 4),
                Text(
                  fidel.transliteration,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
