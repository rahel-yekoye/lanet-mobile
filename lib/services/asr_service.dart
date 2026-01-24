import 'dart:async';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'web_utils_stub.dart' if (dart.library.html) 'web_utils.dart';

import 'package:http_parser/http_parser.dart';

/// Service for Automatic Speech Recognition using Hugging Face Spaces API
/// API endpoint: https://huggingface.co/spaces/tigu1221/lanet-asr-server
class ASRService {
  // Hugging Face Spaces API endpoint
  static const String _baseUrl = 'https://tigu1221-lanet-asr-server.hf.space';
  static const String _apiEndpoint = '$_baseUrl/gradio_api/call/transcribe';
  static const String _uploadEndpoint = '$_baseUrl/gradio_api/upload';

  /// Transcribe audio file using the ASR model
  /// Returns the transcribed text or null if error
  Future<String?> transcribeAudio(dynamic audioFile,
      {String? languageCode}) async {
    try {
      Uint8List audioBytes;
      String? detectedMimeType;

      // Handle Web Blob URLs
      if (kIsWeb && audioFile is String && audioFile.startsWith('blob:')) {
        try {
          final blobData = await fetchBlobData(audioFile);
          audioBytes = blobData.bytes;
          detectedMimeType = blobData.mimeType;
        } catch (e) {
          throw Exception('Failed to fetch blob audio: $e');
        }
      } else if (kIsWeb && isWebFile(audioFile)) {
        audioBytes = await readFileBytesWeb(audioFile);
      } else if (audioFile is String) {
        // Mobile/Desktop file path or HTTP URL
        if (audioFile.startsWith('http')) {
          final response = await http.get(Uri.parse(audioFile));
          audioBytes = response.bodyBytes;
        } else {
          audioBytes = await File(audioFile).readAsBytes();
        }
      } else {
        throw Exception(
            'Unsupported audio file type: ${audioFile.runtimeType}');
      }

      return await _transcribeWithGradio(audioBytes,
          mimeType: detectedMimeType, languageCode: languageCode);
    } catch (e) {
      print('Error transcribing audio: $e');
      rethrow;
    }
  }

  /// Transcribe audio from a path (wrapper for compatibility)
  Future<String?> transcribeAudioFromPath(String audioPath,
      {String? languageCode}) async {
    return transcribeAudio(audioPath, languageCode: languageCode);
  }

  /// Uploads file to Gradio server and returns the server path
  Future<String?> _uploadFile(
      Uint8List bytes, String fileName, String mimeType) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadEndpoint));

      // Parse mime type
      final typeParts = mimeType.split('/');
      final mediaType = MediaType(
          typeParts[0], typeParts.length > 1 ? typeParts[1] : 'octet-stream');

      request.files.add(http.MultipartFile.fromBytes('files', bytes,
          filename: fileName, contentType: mediaType));

      final response = await request.send();
      final respBody = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        print('ASR: Upload failed with status ${response.statusCode}');
        return null;
      }

      final uploadedFiles = jsonDecode(respBody);
      if (uploadedFiles is List && uploadedFiles.isNotEmpty) {
        // Gradio 4/5 response format: list of file paths or objects
        if (uploadedFiles[0] is String) {
          return uploadedFiles[0];
        } else if (uploadedFiles[0] is Map) {
          // Might be {'path': '...', 'url': '...', ...}
          return uploadedFiles[0]['path']; // Prefer path for internal use
        }
      }
      return null;
    } catch (e) {
      print('ASR: Upload error: $e');
      return null;
    }
  }

  /// Internal method to handle Gradio 4/5 interaction
  Future<String?> _transcribeWithGradio(Uint8List audioBytes,
      {String? mimeType, String? languageCode}) async {
    const isWeb = kIsWeb;
    var finalMimeType = mimeType;

    // Fallback if mimeType is missing or generic
    if (finalMimeType == null || finalMimeType == 'application/octet-stream') {
      finalMimeType = isWeb ? 'audio/webm' : 'audio/wav';
    }

    print('ASR: Using mimeType: $finalMimeType, Language: $languageCode');

    String extension = 'wav';
    if (finalMimeType.contains('webm')) {
      extension = 'webm';
    } else if (finalMimeType.contains('mp4'))
      extension = 'mp4';
    else if (finalMimeType.contains('aac'))
      extension = 'm4a';
    else if (finalMimeType.contains('ogg')) extension = 'ogg';

    final fileName = 'audio.$extension';

    // 1. Upload File First (Required for this Space)
    final serverPath = await _uploadFile(audioBytes, fileName, finalMimeType);
    if (serverPath == null) {
      throw Exception('Failed to upload audio file to ASR server');
    }

    print('ASR: File uploaded to $serverPath');

    // 2. Prepare Payload
    final payload = {
      'data': [
        {
          'path': serverPath,
          'orig_name': fileName,
          'size': audioBytes.length,
          'mime_type': finalMimeType,
          'meta': {'_type': 'gradio.FileData'},
        },
        languageCode ??
            'amh' // Use provided language code or default to Amharic
      ]
    };

    // 2. Submit Job (POST)
    final response = await http.post(
      Uri.parse(_apiEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'ASR Submission Failed: ${response.statusCode} - ${response.body}');
    }

    final jsonResponse = jsonDecode(response.body);
    final eventId = jsonResponse['event_id'];
    if (eventId == null) {
      throw Exception('No event_id returned from ASR service');
    }

    // 3. Poll Result (GET SSE Stream)
    try {
      return await _pollResult(eventId);
    } catch (e) {
      throw Exception('Polling failed: $e');
    }
  }

  Future<String?> _pollResult(String eventId) async {
    final Completer<String?> completer = Completer();
    final resultUrl = '$_apiEndpoint/$eventId';

    final client = http.Client();
    try {
      print('Polling ASR result from: $resultUrl');
      final request = http.Request('GET', Uri.parse(resultUrl));
      final response = await client.send(request);

      String buffer = '';
      String? currentEvent;

      response.stream.transform(utf8.decoder).listen((chunk) {
        buffer += chunk;

        while (buffer.contains('\n')) {
          final index = buffer.indexOf('\n');
          final line = buffer.substring(0, index).trim();
          buffer = buffer.substring(index + 1);

          if (line.isEmpty) continue;

          if (line.startsWith('event: ')) {
            currentEvent = line.substring(7).trim();
          } else if (line.startsWith('data: ')) {
            final dataStr = line.substring(6).trim();

            if (currentEvent == 'complete') {
              try {
                final dataJson = jsonDecode(dataStr);
                if (dataJson is List && dataJson.isNotEmpty) {
                  completer.complete(dataJson[0].toString());
                } else {
                  completer.completeError('ASR returned empty data');
                }
              } catch (e) {
                completer.completeError('Error parsing completion data: $e');
              }
              client.close();
              return;
            } else if (currentEvent == 'error') {
              print('ASR Error Event received. Data: "$dataStr"');
              completer.completeError('ASR Error: $dataStr');
              client.close();
              return;
            }
          }
        }
      }, onError: (e) {
        if (!completer.isCompleted) completer.completeError(e);
        client.close();
      }, onDone: () {
        if (!completer.isCompleted) {
          // If stream ends without 'complete' or 'error', it might be a connection drop
          // But sometimes 'complete' is the last thing.
          // If we are here, it means we didn't return yet.
          completer.completeError('Connection closed without result');
        }
        client.close();
      });
    } catch (e) {
      if (!completer.isCompleted) completer.completeError(e);
      client.close();
    }

    return completer.future;
  }

  /// Compare transcribed text with expected text
  /// Returns a similarity score (0.0 to 1.0) and whether it's considered correct
  ASRResult compareTranscription(String transcribed, String expected) {
    // Normalize both strings (lowercase, remove extra spaces)
    final normalizedTranscribed = transcribed.toLowerCase().trim();
    final normalizedExpected = expected.toLowerCase().trim();

    // Exact match
    if (normalizedTranscribed == normalizedExpected) {
      return ASRResult(
        isCorrect: true,
        similarity: 1.0,
        transcribed: transcribed,
        expected: expected,
      );
    }

    // Calculate similarity using Levenshtein distance for better accuracy
    final similarity =
        _calculateSimilarity(normalizedTranscribed, normalizedExpected);

    // Consider correct if similarity is above 0.7 (70% match)
    final isCorrect = similarity >= 0.7;

    return ASRResult(
      isCorrect: isCorrect,
      similarity: similarity,
      transcribed: transcribed,
      expected: expected,
    );
  }

  /// Calculate string similarity (0.0 to 1.0) using Levenshtein distance
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Use a simpler word-based overlap if Levenshtein is too strict for long phrases
    // But for short phrases, Levenshtein is standard.
    // Let's implement Levenshtein on characters.

    List<int> prev = List<int>.generate(s2.length + 1, (i) => i);
    List<int> curr = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1, // insertion
          prev[j + 1] + 1, // deletion
          prev[j] + cost // substitution
        ].reduce((min, val) => val < min ? val : min);
      }
      // Swap arrays
      final temp = prev;
      prev = curr;
      curr = temp;
    }

    final distance = prev[s2.length];
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }
}

/// Result of ASR transcription comparison
class ASRResult {
  final bool isCorrect;
  final double similarity; // 0.0 to 1.0
  final String transcribed;
  final String expected;

  ASRResult({
    required this.isCorrect,
    required this.similarity,
    required this.transcribed,
    required this.expected,
  });
}
