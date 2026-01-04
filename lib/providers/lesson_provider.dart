import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/phrase.dart';
import '../services/dataset_service.dart';

final lessonProvider = ChangeNotifierProvider<LessonProvider>((ref) {
  return LessonProvider(DatasetService());
});

class LessonProvider extends ChangeNotifier {
  final DatasetService _datasetService;
  Map<String, List<Phrase>> byCategory = {};
  List<String> categories = [];
  bool loading = true;
  String? error;

  LessonProvider(this._datasetService);

  Future<void> load(String assetPath) async {
    try {
      loading = true;
      error = null;
      notifyListeners();
      
      byCategory = await _datasetService.loadByCategory(assetPath);
      categories = byCategory.keys.toList()..sort();
    } catch (e) {
      error = 'Failed to load lessons: ${e.toString()}';
      debugPrint('Error loading lessons: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  List<Phrase> phrasesFor(String category) {
    return byCategory[category] ?? [];
  }
}