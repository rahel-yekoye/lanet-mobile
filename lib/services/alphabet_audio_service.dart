import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Service to handle alphabet audio playback
/// Maps alphabet characters to their corresponding audio files
class AlphabetAudioService {
  static final AlphabetAudioService _instance =
      AlphabetAudioService._internal();
  factory AlphabetAudioService() => _instance;
  AlphabetAudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;

  /// Get the audio file path for a given alphabet character
  /// Returns the file path in the format: alphabets/{character}.m4a
  String getAudioFilePath(String character) {
    if (character.isEmpty) return '';
    // The audio files are named with the character itself (e.g., ሀ.m4a)
    return 'audio/alphabets/$character.m4a';
  }

  /// Play audio for a given alphabet character
  /// Returns true if audio was found and started playing, false otherwise
  Future<bool> playAlphabetAudio(String character) async {
    if (character.isEmpty) return false;

    try {
      // Stop any currently playing audio
      if (_isPlaying) {
        await _audioPlayer.stop();
        await Future.delayed(const Duration(milliseconds: 50));
      }

      final audioPath = getAudioFilePath(character);
      // AssetSource path should be relative to assets folder
      // Since pubspec.yaml has: assets/audio/alphabets/
      // The path should be: assets/audio/alphabets/character.m4a
      final fullPath = audioPath;

      debugPrint('Playing audio: $fullPath for character: $character');

      // Set source and play
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.play(AssetSource(fullPath));

      _isPlaying = true;

      // Wait a bit to ensure audio starts playing and catch any errors
      await Future.delayed(const Duration(milliseconds: 200));

      // Check if audio is actually playing
      final state = _audioPlayer.state;
      if (state == PlayerState.playing) {
        debugPrint('Audio is playing successfully');
        return true;
      } else {
        debugPrint('Audio state: $state');
        // Try again - sometimes it needs a moment
        await Future.delayed(const Duration(milliseconds: 100));
        return _audioPlayer.state == PlayerState.playing;
      }
    } catch (e) {
      debugPrint('Error playing audio for character $character: $e');
      _isPlaying = false;
      return false;
    }
  }

  /// Stop currently playing audio
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
    } catch (e) {
      debugPrint('Error stopping audio: $e');
    }
  }

  /// Dispose the audio player
  void dispose() {
    _audioPlayer.dispose();
  }
}
