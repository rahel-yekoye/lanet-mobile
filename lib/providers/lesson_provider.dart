import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/phrase.dart';
import '../services/dataset_service.dart';
import '../services/onboarding_service.dart';
import '../services/admin_service.dart';
import '../models/admin_models.dart';
import '../config/supabase_config.dart';

final lessonProvider = ChangeNotifierProvider<LessonProvider>((ref) {
  return LessonProvider(DatasetService());
});

class LessonProvider extends ChangeNotifier {
  final DatasetService _datasetService;
  Map<String, List<Phrase>> byCategory = {};
  List<String> categories = [];
  bool loading = true;
  String? error;
  Map<String, Lesson> _supabaseLessons = {}; // Store Supabase lessons by category

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
      
      // Load all categories first (preserving CSV order if using CSV)
      byCategory = await _datasetService.loadByCategory(assetPath);
      
      // Get user's selected language
      // Priority: 1. Passed argument, 2. OnboardingService (local), 3. Null (all)
      final userLanguage = language ?? await OnboardingService.getValue(OnboardingService.keyLanguage);
      _currentLanguage = userLanguage;
      
      // Filter categories by user's selected language if available
      if (userLanguage != null && userLanguage.isNotEmpty) {
        byCategory = _datasetService.filterCategoriesByLanguage(byCategory, userLanguage);
      }
      
      // Also fetch published lessons from Supabase and add them as categories
      if (!SupabaseConfig.isDemoMode) {
        try {
          final supabaseLessonsResult = await AdminService.getLessons(
            status: 'published',
            pageSize: 100, // Get all published lessons
          );
          // AdminService.getLessons already returns Lesson objects, not maps
          final lessonsList = supabaseLessonsResult['lessons'] as List;
          final supabaseLessons = <Lesson>[];
          for (final item in lessonsList) {
            if (item is Lesson) {
              supabaseLessons.add(item);
            } else if (item is Map<String, dynamic>) {
              // Fallback: if it's a map, convert it
              supabaseLessons.add(Lesson.fromJson(item));
            }
          }
          
          // Filter by user's language if available
          final filteredLessons = userLanguage != null && userLanguage.isNotEmpty
              ? supabaseLessons.where((lesson) {
                  // Match language (handle different formats)
                  final lessonLang = lesson.language.toLowerCase();
                  final userLang = userLanguage.toLowerCase();
                  return lessonLang.contains(userLang) || 
                         userLang.contains(lessonLang) ||
                         (userLang == 'tigrigna' && lessonLang == 'tigrinya') ||
                         (userLang == 'oromo' && lessonLang.contains('oromo'));
                }).toList()
              : supabaseLessons;
          
          // Add Supabase lessons as categories
          for (final lesson in filteredLessons) {
            final categoryName = lesson.category ?? lesson.title;
            if (categoryName != null && categoryName.isNotEmpty) {
              // If category doesn't exist, create it
              if (!byCategory.containsKey(categoryName)) {
                byCategory[categoryName] = [];
              }
              // Store the Supabase lesson for reference
              _supabaseLessons[categoryName] = lesson;
              
              // Create a placeholder phrase to represent the Supabase lesson
              // This allows it to be displayed and clicked
              if (byCategory[categoryName]!.isEmpty) {
                byCategory[categoryName]!.add(Phrase(
                  english: lesson.title,
                  amharic: lesson.description ?? '',
                  oromo: '',
                  tigrinya: '',
                  category: categoryName,
                ));
              }
            }
          }
        } catch (e) {
          debugPrint('Error loading Supabase lessons: $e');
          // Don't fail completely if Supabase fetch fails
        }
      }
      
      categories = byCategory.keys.toList();
      final gf = categories.indexWhere(
        (c) => c.toLowerCase().contains('greetings') || c.toLowerCase().contains('farewell'),
      );
      if (gf > 0) {
        final cat = categories.removeAt(gf);
        categories.insert(0, cat);
      }
    } catch (e) {
      error = 'Failed to load lessons: ${e.toString()}';
      debugPrint('Error loading lessons: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }
  
  /// Get Supabase lesson for a category (if it exists)
  Lesson? getSupabaseLesson(String category) {
    return _supabaseLessons[category];
  }
  
  /// Check if a category is a Supabase lesson
  bool isSupabaseLesson(String category) {
    return _supabaseLessons.containsKey(category);
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
