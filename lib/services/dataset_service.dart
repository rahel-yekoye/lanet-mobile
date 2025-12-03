import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/phrase.dart';

class DatasetService {
  Future<List<Phrase>> loadAllPhrases(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(raw);

    final List<Phrase> all = [];
    data.forEach((category, items) {
      if (items is List) {
        for (final it in items) {
          if (it is Map<String, dynamic>) {
            all.add(Phrase.fromMap(it, category));
          } else if (it is Map) {
            all.add(Phrase.fromMap(Map<String, dynamic>.from(it), category));
          }
        }
      }
    });
    return all;
  }

  Future<Map<String, List<Phrase>>> loadByCategory(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(raw);
    final Map<String, List<Phrase>> out = {};
    data.forEach((category, items) {
      out[category] = [];
      if (items is List) {
        for (final it in items) {
          out[category]!.add(Phrase.fromMap(Map<String, dynamic>.from(it), category));
        }
      }
    });
    return out;
  }
}
