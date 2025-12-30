import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lanet_mobile/models/fidel_model.dart';
import '../models/phrase.dart';

class DatasetService {
  /// -------------------------------
  /// JSON PHRASES (unchanged)
  /// -------------------------------
  Future<List<Phrase>> loadAllPhrases(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(raw);

    final List<Phrase> all = [];
    data.forEach((category, items) {
      if (items is List) {
        for (final it in items) {
          all.add(
            Phrase.fromMap(
              Map<String, dynamic>.from(it),
              category,
            ),
          );
        }
      }
    });
    return all;
  }

  Future<Map<String, List<Phrase>>> loadByCategory(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final Map<String, dynamic> data = json.decode(raw);

    final Map<String, List<Phrase>> out = {};
    data.forEach((category, items) {
      out[category] = [];
      if (items is List) {
        for (final it in items) {
          out[category]!.add(
            Phrase.fromMap(
              Map<String, dynamic>.from(it),
              category,
            ),
          );
        }
      }
    });
    return out;
  }

  /// -------------------------------
  /// PURE DART CSV PARSER FOR FIDEL
  /// -------------------------------
  Future<List<FidelModel>> loadFidel() async {
    final raw =
        await rootBundle.loadString('assets/data/level_0_fidel.csv');

    final lines = const LineSplitter().convert(raw);

    if (lines.isEmpty) return [];

    final headers = lines.first.split(',');

    final List<FidelModel> out = [];

    for (int i = 1; i < lines.length; i++) {
      final values = lines[i].split(',');

      if (values.length != headers.length) continue;

      final Map<String, String> row = {};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j].trim()] = values[j].trim();
      }

      out.add(FidelModel.fromCsv(row));
    }

    return out;
  }
}
