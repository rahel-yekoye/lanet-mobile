import 'package:flutter/material.dart';
import '../models/phrase.dart';
import '../services/dataset_service.dart';

class LessonProvider extends ChangeNotifier {
  final DatasetService _ds = DatasetService();
  Map<String, List<Phrase>> byCategory = {};
  List<String> categories = [];
  bool loading = true;

  Future<void> load(String assetPath) async {
    loading = true;
    notifyListeners();
    byCategory = await _ds.loadByCategory(assetPath);
    categories = byCategory.keys.toList()..sort();
    loading = false;
    notifyListeners();
  }

  List<Phrase> phrasesFor(String category) {
    return List.unmodifiable(byCategory[category] ?? []);
  }
}
