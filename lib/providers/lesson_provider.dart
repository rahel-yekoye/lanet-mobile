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

  String? _currentLanguage;

  LessonProvider(this._datasetService);

  Future<void> load(String assetPath, {String? language}) async {
    try {
      // Defer state update to next microtask to avoid "setState during build" errors
      // if called from ProxyProvider.update
      await Future.microtask(() {
        loading = true;
        error = null;
        notifyListeners();
      });
      
      // Load all categories first
      byCategory = await _datasetService.loadByCategory(assetPath);
      
      // Get user's selected language
      // Priority: 1. Passed argument, 2. OnboardingService (local), 3. Null (all)
      final userLanguage = language ?? await OnboardingService.getValue(OnboardingService.keyLanguage);
      _currentLanguage = userLanguage;
      
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

  // Helper to update language if changed
  void updateLanguage(String assetPath, String? language) {
    if (language != null && language != _currentLanguage) {
      _currentLanguage = language; // Update immediately to prevent repeated calls
      load(assetPath, language: language);
    }
  }

  List<Phrase> phrasesFor(String category) {
    return byCategory[category] ?? [];
  }
}