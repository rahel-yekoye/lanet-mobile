import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/phrase.dart';
import '../services/dataset_service.dart';
import '../services/onboarding_service.dart';

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
      
      // Load all categories first
      byCategory = await _datasetService.loadByCategory(assetPath);
      
      // Get user's selected language
      final userLanguage = await OnboardingService.getValue(OnboardingService.keyLanguage);
      
      // Filter categories by user's selected language if available
      if (userLanguage != null && userLanguage.isNotEmpty) {
        byCategory = _datasetService.filterCategoriesByLanguage(byCategory, userLanguage);
      }
      
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