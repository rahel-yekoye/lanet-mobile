import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SRSService {
  static const _kKey = 'srs_progress_v1';

  Future<Map<String, dynamic>> _readAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_kKey);
    if (raw == null) return {};
    return json.decode(raw) as Map<String, dynamic>;
  }

  Future<void> _writeAll(Map<String, dynamic> m) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kKey, json.encode(m));
  }

  String _keyFor(String category, String english) => '$category||$english';

  Future<Map<String, dynamic>> getProgress(String category, String english) async {
    final all = await _readAll();
    final k = _keyFor(category, english);
    return all[k] ?? {};
  }

  Future<void> markCorrect(String category, String english) async {
    final all = await _readAll();
    final k = _keyFor(category, english);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final cur = all[k] ?? {'box': 1, 'nextReview': now};
    int box = (cur['box'] ?? 1) as int;
    box = (box >= 5) ? 5 : box + 1;
    final delta = _boxToSeconds(box);
    all[k] = {'box': box, 'nextReview': now + delta * 1000};
    await _writeAll(all);
  }

  Future<void> markWrong(String category, String english) async {
    final all = await _readAll();
    final k = _keyFor(category, english);
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    // Demote to box 1
    all[k] = {'box': 1, 'nextReview': now + _boxToSeconds(1) * 1000};
    await _writeAll(all);
  }

  int _boxToSeconds(int box) {
    // simple schedule: box 1: 1m, box2: 1h, box3: 1d, box4: 3d, box5: 7d
    switch (box) {
      case 1:
        return 60; // 1 minute (for quick review)
      case 2:
        return 3600; // 1 hour
      case 3:
        return 86400; // 1 day
      case 4:
        return 86400 * 3;
      case 5:
      default:
        return 86400 * 7;
    }
  }

  Future<List<Map<String, dynamic>>> dueNow(List<Map<String, String>> phraseList) async {
    final all = await _readAll();
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final due = <Map<String, dynamic>>[];
    for (final p in phraseList) {
      final k = _keyFor(p['category']!, p['english']!);
      final record = all[k];
      if (record == null || (record['nextReview'] ?? 0) <= now) {
        due.add(p);
      }
    }
    return due;
  }
}
