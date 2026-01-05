import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:lanet_mobile/models/fidel_model.dart';
import 'package:lanet_mobile/widgets/cultural_border.dart';
import 'package:lanet_mobile/widgets/speech_practice.dart';
import 'package:lanet_mobile/services/srs_service.dart';
import 'package:google_fonts/google_fonts.dart';

class LetterDetailScreen extends StatefulWidget {
  final FidelModel fidel;

  const LetterDetailScreen({required this.fidel, super.key});

  @override
  State<LetterDetailScreen> createState() => _LetterDetailScreenState();
}

class _LetterDetailScreenState extends State<LetterDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SRSService _srs = SRSService();

  Future<void> _playAudio() async {
    if (widget.fidel.audioFile.isNotEmpty) {
      await _audioPlayer
          .play(AssetSource('assets/audio/${widget.fidel.audioFile}'));
    } else {
      // Optional: fallback sound or message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audio not available yet')),
      );
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CulturalScaffold(
      headerImage: 'village.png', // Or a specific illustration per letter later
      showTopBorder: true,
      showBottomBorder: true,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Big Fidel Character
            Text(
              widget.fidel.character,
              style: GoogleFonts.notoSansEthiopic(fontSize: 140),
            ),
            const SizedBox(height: 32),

            // Transliteration
            Text(
              widget.fidel.transliteration,
              style: const TextStyle(fontSize: 48, color: Colors.brown),
            ),
            const SizedBox(height: 8),

            // Vowel (if any)
            if (widget.fidel.vowel.isNotEmpty)
              Text(
                widget.fidel.vowel,
                style:
                    const TextStyle(fontSize: 32, color: Colors.orangeAccent),
              ),

            const SizedBox(height: 60),

            // Play Audio Button
            ElevatedButton.icon(
              onPressed: _playAudio,
              icon: const Icon(Icons.volume_up, size: 36),
              label: const Text(
                'Hear Pronunciation',
                style: TextStyle(fontSize: 24),
              ),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                backgroundColor: Colors.deepOrange.shade400,
              ),
            ),

            const SizedBox(height: 24),

            SpeechPractice(
              prompt: 'Repeat this sound',
              targetText: widget.fidel.character,
              onResult: (ok) async {
                if (ok) {
                  await _srs.markCorrect('alphabet', widget.fidel.character);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Good pronunciation!'),
                      ),
                    );
                  }
                } else {
                  await _srs.markWrong('alphabet', widget.fidel.character);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.orange,
                        content: Text('Try again'),
                      ),
                    );
                  }
                }
              },
            ),

            const Spacer(),

            // Future: Add example words, writing trace, etc.
            const Text(
              'Example words and writing practice coming soon!',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
