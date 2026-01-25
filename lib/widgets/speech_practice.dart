import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:record/record.dart' as record_pkg;
import '../services/asr_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart' as jaudio;
import 'package:percent_indicator/percent_indicator.dart';
import 'package:confetti/confetti.dart';

/// Speech practice widget similar to Duolingo
/// Shows a phrase and allows user to record their pronunciation
class SpeechPractice extends StatefulWidget {
  final String prompt; // English prompt
  final String
      targetText; // The text user should speak (e.g., Amharic, Oromo, Tigrinya)
  final Function(bool correct) onResult;

  const SpeechPractice({
    super.key,
    required this.prompt,
    required this.targetText,
    required this.onResult,
  });

  @override
  State<SpeechPractice> createState() => _SpeechPracticeState();
}

class _SpeechPracticeState extends State<SpeechPractice>
    with SingleTickerProviderStateMixin {
  final record_pkg.AudioRecorder _audioRecorder = record_pkg.AudioRecorder();
  final ASRService _asrService = ASRService();
  final AudioPlayer _player = AudioPlayer();
  jaudio.AudioPlayer? _jaPlayer;
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(milliseconds: 900));

  bool _isRecording = false;
  bool _isProcessing = false;
  String? _recordedText;
  ASRResult? _result;
  String? _audioPath;
  String? _languageOverride;
  double _playbackRate = 1.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (kIsWeb) {
      _jaPlayer = jaudio.AudioPlayer();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    _confetti.dispose();
    _player.dispose();
    try {
      _jaPlayer?.dispose();
    } catch (_) {}
    try {
      if (!kIsWeb && _audioPath != null) {
        final f = File(_audioPath!);
        if (f.existsSync()) {
          f.deleteSync();
        }
      }
    } catch (_) {}
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      // Check if we have permission
      if (!await _audioRecorder.hasPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission is required')),
          );
        }
        return;
      }
      // Get path for recording
      if (kIsWeb) {
        // On web, generate a simple path (record package will handle it)
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        _audioPath = 'recording_$timestamp.m4a';
      } else {
        // On mobile/desktop, use temporary directory
        try {
          final directory = await getTemporaryDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _audioPath = '${directory.path}/recording_$timestamp.m4a';
        } catch (e) {
          debugPrint('Warning: Could not get temporary directory: $e');
          // Generate a fallback path
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          _audioPath = 'recording_$timestamp.m4a';
        }
      }

      // Start recording with path (required by record package)
      await _audioRecorder.start(
        const record_pkg.RecordConfig(
          encoder: record_pkg.AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _audioPath!,
      );

      setState(() {
        _isRecording = true;
        _recordedText = null;
        _result = null;
      });
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      if (!_isRecording) return;

      final path = await _audioRecorder.stop();
      if (path != null) {
        _audioPath = path;
      }

      setState(() {
        _isRecording = false;
        _isProcessing = true;
      });

      // Process the audio
      await _processAudio();
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processAudio() async {
    if (_audioPath == null) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    try {
      // Determine language from target text
      // Heuristic: If text contains Ethiopic characters, assume Amharic (amh)
      // Otherwise, assume Oromo (orm) which uses Latin script
      final hasEthiopic =
          RegExp(r'[\u1200-\u137F]').hasMatch(widget.targetText);
      final languageCode = _languageOverride ?? (hasEthiopic ? 'amh' : 'orm');

      debugPrint('Detected language for "${widget.targetText}": $languageCode');

      // Transcribe audio - handle web and mobile differently
      String? transcribed;

      if (kIsWeb) {
        // On web, the record package should handle the file reading
        // The audio path is typically a blob URL that can be fetched directly
        transcribed = await _asrService.transcribeAudioFromPath(_audioPath!,
            languageCode: languageCode);
      } else {
        // On mobile/desktop, use the path directly
        transcribed = await _asrService.transcribeAudio(_audioPath!,
            languageCode: languageCode);

        // Keep audio file so learner can play back their recording
      }

      // Compare with expected text
      if (transcribed == null) throw Exception('Transcription failed');
      final result = _asrService.compareTranscription(
        transcribed,
        widget.targetText,
      );

      setState(() {
        _isProcessing = false;
        _recordedText = transcribed;
        _result = result;
      });
      if (result.similarity >= 0.9) {
        _confetti.play();
      }

      // Call callback
      widget.onResult(result.isCorrect);
    } catch (e) {
      debugPrint('Error processing audio: $e');
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        // Show detailed error in a dialog or cleaner snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                    child: Text('Transcription failed. Please try again.')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Error Details'),
                    content: Text(e.toString()),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      )
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              shouldLoop: false,
              blastDirectionality: BlastDirectionality.explosive,
              numberOfParticles: 20,
              maxBlastForce: 20,
              minBlastForce: 5,
            ),
          ),
          const SizedBox(height: 20),

          // Prompt (English)
          Text(
            widget.prompt,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 30),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Auto'),
                selected: _languageOverride == null,
                onSelected: (s) {
                  setState(() => _languageOverride = null);
                },
              ),
              ChoiceChip(
                label: const Text('Amharic'),
                selected: _languageOverride == 'amh',
                onSelected: (s) {
                  setState(() => _languageOverride = 'amh');
                },
              ),
              ChoiceChip(
                label: const Text('Oromo'),
                selected: _languageOverride == 'orm',
                onSelected: (s) {
                  setState(() => _languageOverride = 'orm');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Target text to speak
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.teal.shade200, width: 2),
            ),
            child: Text(
              widget.targetText,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Colors.teal.shade900,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Instructions
          Text(
            _isRecording
                ? '🎤 Recording... Tap to stop'
                : _isProcessing
                    ? '🔄 Processing your speech...'
                    : 'Tap the microphone to start recording',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),

          const SizedBox(height: 30),

          // Microphone button
          GestureDetector(
            onTap: _isRecording ? _stopRecording : _startRecording,
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording
                          ? Colors.red.shade400
                          : _isProcessing
                              ? Colors.grey.shade400
                              : Colors.teal.shade400,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording
                                  ? Colors.red
                                  : _isProcessing
                                      ? Colors.grey
                                      : Colors.teal)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isRecording
                          ? Icons.stop
                          : _isProcessing
                              ? Icons.hourglass_empty
                              : Icons.mic,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 40),

          // Result display
          if (_result != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _result!.isCorrect
                    ? Colors.green.shade50
                    : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _result!.isCorrect
                      ? Colors.green.shade300
                      : Colors.orange.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _result!.isCorrect ? Icons.check_circle : Icons.warning,
                        color:
                            _result!.isCorrect ? Colors.green : Colors.orange,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _result!.isCorrect
                            ? 'Great job! 🎉'
                            : 'Almost there! 💪',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _result!.isCorrect
                              ? Colors.green.shade900
                              : Colors.orange.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_recordedText != null) ...[
                    Text(
                      'You said:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RichText(
                      textAlign: TextAlign.center,
                      text: _buildDiffSpan(_recordedText!, widget.targetText,
                          youSaid: true),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: _buildDiffSpan(widget.targetText, _recordedText!,
                          youSaid: false),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Similarity: ${(_result!.similarity * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearPercentIndicator(
                      lineHeight: 8,
                      percent: _result!.similarity.clamp(0.0, 1.0),
                      barRadius: const Radius.circular(6),
                      progressColor:
                          _result!.isCorrect ? Colors.green : Colors.orange,
                      backgroundColor: Colors.grey.shade300,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _audioPath == null
                              ? null
                              : () async {
                                  try {
                                    if (kIsWeb) {
                                      // Use just_audio on web (handles blob: URLs reliably)
                                      _jaPlayer ??= jaudio.AudioPlayer();
                                      await _jaPlayer!.setUrl(_audioPath!);
                                      await _jaPlayer!.setSpeed(_playbackRate);
                                      await _jaPlayer!.play();
                                    } else {
                                      await _player
                                          .setPlaybackRate(_playbackRate);
                                      await _player
                                          .play(DeviceFileSource(_audioPath!));
                                    }
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Cannot play audio: $e'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Hear your recording'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            setState(() {
                              _playbackRate = _playbackRate == 1.0 ? 0.85 : 1.0;
                            });
                            await _player.setPlaybackRate(_playbackRate);
                          },
                          icon: const Icon(Icons.speed),
                          label: Text(_playbackRate == 1.0
                              ? 'Slow 0.85x'
                              : 'Normal 1.0x'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _recordedText = null;
                              _result = null;
                            });
                            _startRecording();
                          },
                          icon: const Icon(Icons.replay),
                          label: const Text('Try again'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  TextSpan _buildDiffSpan(String primary, String compare,
      {required bool youSaid}) {
    final spans = <TextSpan>[];
    final len =
        primary.length > compare.length ? primary.length : compare.length;
    for (int i = 0; i < len; i++) {
      final pChar = i < primary.length ? primary[i] : '';
      final cChar = i < compare.length ? compare[i] : '';
      final match = pChar == cChar && pChar.isNotEmpty;
      spans.add(TextSpan(
        text: pChar.isEmpty ? '' : pChar,
        style: TextStyle(
          fontSize: youSaid ? 20 : 18,
          fontWeight: youSaid ? FontWeight.w500 : FontWeight.w400,
          color: match ? Colors.green.shade800 : Colors.red.shade700,
        ),
      ));
    }
    final label = youSaid ? '' : 'Expected: ';
    return TextSpan(children: [
      if (!youSaid)
        TextSpan(
          text: label,
          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
        ),
      ...spans,
    ]);
  }
}
