import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lanet_mobile/models/fidel_model.dart';
import '../models/phrase.dart';

class DatasetService {
  /// -------------------------------
  /// JSON PHRASES (with language filtering)
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

  /// Filter phrases by user's selected language
  List<Phrase> filterByLanguage(List<Phrase> phrases, String selectedLanguage) {
    return phrases.where((phrase) {
      switch(selectedLanguage.toLowerCase()) {
        case 'amharic':
          return phrase.amharic.isNotEmpty;
        case 'tigrinya':
        case 'tigrigna': // Handle both spellings
          return phrase.tigrinya.isNotEmpty;
        case 'oromo':
        case 'oromigna':
          return phrase.oromo.isNotEmpty;
        default:
          return false;
      }
    }).toList();
  }

  /// Filter categories by user's selected language
  Map<String, List<Phrase>> filterCategoriesByLanguage(
    Map<String, List<Phrase>> categories,
    String selectedLanguage,
  ) {
    final filteredCategories = <String, List<Phrase>>{};
    
    categories.forEach((category, phrases) {
      final filteredPhrases = filterByLanguage(phrases, selectedLanguage);
      if (filteredPhrases.isNotEmpty) {
        filteredCategories[category] = filteredPhrases;
      }
    });
    
    return filteredCategories;
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
