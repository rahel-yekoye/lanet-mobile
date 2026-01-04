import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:just_audio/just_audio.dart' as jaudio;
import 'dart:async';
// Web speech is handled via FlutterTts across platforms to avoid web-only imports

class TTSService {
  static final TTSService _instance = TTSService._internal();
  factory TTSService() => _instance;
  TTSService._internal();

  final FlutterTts _tts = FlutterTts();
  Map<int, String>? _ethiopicMap; // Unicode code point -> transliteration
  static const String _remoteEndpoint = String.fromEnvironment(
      'HASAB_TTS_ENDPOINT',
      defaultValue: 'https://hasab.co/v1/tts/synthesize');
  static const String _remoteApiKey =
      String.fromEnvironment('HASAB_API_KEY', defaultValue: '');
  static const String _preferredSpeaker =
      String.fromEnvironment('HASAB_TTS_SPEAKER', defaultValue: '');
  static const String _speakerAmh =
      String.fromEnvironment('HASAB_TTS_SPEAKER_AMH', defaultValue: '');
  static const String _speakerTir =
      String.fromEnvironment('HASAB_TTS_SPEAKER_TIR', defaultValue: '');
  static const String _speakerOro =
      String.fromEnvironment('HASAB_TTS_SPEAKER_ORO', defaultValue: '');
  static const String _speakerEng =
      String.fromEnvironment('HASAB_TTS_SPEAKER_ENG', defaultValue: '');
  static const String _proxyEndpoint =
      String.fromEnvironment('HASAB_TTS_PROXY', defaultValue: '');
  jaudio.AudioPlayer? _webPlayer;
  final ap.AudioPlayer _mobilePlayer = ap.AudioPlayer();

  Future<void> _ensureTranslit() async {
    if (_ethiopicMap != null) return;
    try {
      final csv = await rootBundle.loadString('assets/data/level_0_fidel.csv');
      final lines = csv.split('\n');
      final map = <int, String>{};
      for (final line in lines.skip(1)) {
        if (line.trim().isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 7) continue;
        final ch = parts[4];
        final tr = parts[5];
        if (ch.isNotEmpty) {
          map[ch.codeUnitAt(0)] = tr.replaceAll('ɨ', 'i');
        }
      }
      _ethiopicMap = map;
    } catch (_) {
      _ethiopicMap = {};
    }
  }

  Future<String> _romanizeIfEthiopic(String text) async {
    final hasEthiopic = RegExp(r'[\u1200-\u137F]').hasMatch(text);
    if (!hasEthiopic) return text;
    await _ensureTranslit();
    final sb = StringBuffer();
    for (final ch in text.runes) {
      final tr = _ethiopicMap![ch];
      sb.write(tr ?? String.fromCharCode(ch));
    }
    return sb.toString();
  }

  Future<void> speak(String text, {String? langCode}) async {
    if (text.trim().isEmpty) return;
    final lc = _mapLang(langCode);
    String speakText = text;
    String? speakLang = lc;
    if (lc == 'am-ET' || lc == 'ti-ET') {
      speakText = await _romanizeIfEthiopic(text);
      speakLang = 'en-US';
    }
    // Use FlutterTts for both web and mobile
    try {
      String target = speakLang ?? 'en-US';
      try {
        final langs = await _tts.getLanguages as List<dynamic>?;
        if (langs != null && !langs.contains(target)) {
          target = 'en-US';
        }
      } catch (_) {}
      await _tts.setLanguage(target);
      await _tts.setSpeechRate(0.85);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      await _tts.speak(speakText);
    } catch (_) {}
  }

  Future<bool> play(String text, {String? langCode}) async {
    // Try remote synthesis first if configured
    if (_remoteEndpoint.isNotEmpty) {
      final urlOrPath = await _synthesizeRemote(text, langCode: langCode);
      if (urlOrPath != null) {
        try {
          if (kIsWeb) {
            _webPlayer ??= jaudio.AudioPlayer();
            await _webPlayer!.setUrl(urlOrPath);
            await _webPlayer!.play();
          } else {
            await _mobilePlayer.play(ap.DeviceFileSource(urlOrPath));
          }
          return true;
        } catch (_) {
          // Fall back to speak below
        }
      }
    }
    await speak(text, langCode: langCode);
    return false;
  }

  Future<String?> _synthesizeRemote(String text, {String? langCode}) async {
    try {
      // On web, direct calls can be blocked by CORS. Respect proxy if provided.
      if (kIsWeb && _proxyEndpoint.isEmpty) {
        return null;
      }
      // No explicit offline check; HTTP failure will trigger fallback
      final hasabLang = _mapToHasabLang(langCode);
      final headers = {
        'Content-Type': 'application/json',
        if (_remoteApiKey.isNotEmpty) 'Authorization': 'Bearer $_remoteApiKey',
      };
      String? sp;
      if (_preferredSpeaker.isNotEmpty) {
        sp = _preferredSpeaker;
      } else {
        switch (hasabLang) {
          case 'amh':
            sp = _speakerAmh.isNotEmpty ? _speakerAmh : 'hanna';
            break;
          case 'tir':
            sp = _speakerTir.isNotEmpty ? _speakerTir : 'selam';
            break;
          case 'oro':
            sp = _speakerOro.isNotEmpty ? _speakerOro : null;
            break;
          case 'eng':
            sp = _speakerEng.isNotEmpty ? _speakerEng : null;
            break;
          default:
            sp = null;
        }
      }
      final req = {
        'text': text,
        'language': hasabLang,
        if (sp != null) 'speaker_name': sp,
      };
      final body = json.encode(req);
      final endpoint = (kIsWeb && _proxyEndpoint.isNotEmpty)
          ? _proxyEndpoint
          : _remoteEndpoint;
      final url = Uri.parse(endpoint);
      final resp = await http
          .post(url, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;

      // Attempt binary audio first
      Uint8List bytes = resp.bodyBytes;
      if (bytes.isEmpty) {
        // Fallback: try JSON structure
        final data = json.decode(resp.body);
        if (data is Map && data['audio_url'] is String) {
          return data['audio_url'] as String;
        }
        if (data is Map && data['audio_base64'] is String) {
          bytes = base64Decode(data['audio_base64'] as String);
        }
      }
      if (bytes.isEmpty) return null;
      if (kIsWeb) {
        // Write to a temporary blob via a data URI
        final b64 = base64Encode(bytes);
        return 'data:audio/mp3;base64,$b64';
      } else {
        final dir = await getTemporaryDirectory();
        final p =
            '${dir.path}/tts_${DateTime.now().millisecondsSinceEpoch}.mp3';
        final f = File(p);
        await f.writeAsBytes(bytes, flush: true);
        return p;
      }
    } catch (_) {
      return null;
    }
  }

  String _mapToHasabLang(String? langCode) {
    switch (langCode) {
      case 'amh':
      case 'amharic':
      case 'am-ET':
        return 'amh';
      case 'tir':
      case 'tigrinya':
      case 'ti-ET':
        return 'tir';
      case 'om-ET':
      case 'oromo':
      case 'orm':
        return 'oro';
      case 'eng':
      case 'en':
      case 'english':
        return 'eng';
      default:
        return 'oro';
    }
  }

  String? _mapLang(String? lang) {
    switch (lang) {
      case 'amharic':
      case 'amh':
        return 'am-ET';
      case 'oromo':
      case 'orm':
        return 'om-ET';
      case 'tigrinya':
      case 'tir':
      case 'ti':
        return 'ti-ET';
      default:
        return lang;
    }
  }
}
