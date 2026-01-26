import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_models.dart';
import '../config/supabase_config.dart';
import 'dart:developer' as developer;

class ExerciseService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Get all exercises for a lesson
  static Future<List<Exercise>> getExercisesForLesson(String lessonId) async {
    if (SupabaseConfig.isDemoMode) {
      // Return demo exercises
      return [
        Exercise(
          id: 'demo-1',
          lessonId: lessonId,
          type: 'multiple-choice',
          prompt: 'What is the correct translation?',
          options: {
            'options': ['Option 1', 'Option 2', 'Option 3', 'Option 4']
          },
          correctAnswer: 'Option 1',
          points: 5,
          orderIndex: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
    }

    try {
      final response = await _client
          .from('exercises')
          .select()
          .eq('lesson_id', lessonId)
          .order('order_index');

      return (response as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('Error fetching exercises: $e');
      throw Exception('Failed to fetch exercises: $e');
    }
  }

  /// Save exercise progress
  static Future<void> saveExerciseProgress({
    required String exerciseId,
    required String lessonId,
    required bool isCorrect,
    required int pointsEarned,
  }) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('user_exercise_progress').upsert({
        'user_id': userId,
        'exercise_id': exerciseId,
        'lesson_id': lessonId,
        'is_correct': isCorrect,
        'points_earned': pointsEarned,
        'completed_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('Error saving exercise progress: $e');
      // Don't throw - progress saving is non-critical
    }
  }

  /// Get lesson completion status
  static Future<bool> isLessonCompleted(String lessonId) async {
    if (SupabaseConfig.isDemoMode) return false;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('user_lesson_progress')
          .select('completed')
          .eq('user_id', userId)
          .eq('lesson_id', lessonId)
          .maybeSingle();

      return response?['completed'] == true;
    } catch (e) {
      developer.log('Error checking lesson completion: $e');
      return false;
    }
  }

  /// Mark lesson as completed
  static Future<void> markLessonCompleted(String lessonId, int totalXpEarned) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      await _client.from('user_lesson_progress').upsert({
        'user_id': userId,
        'lesson_id': lessonId,
        'completed': true,
        'xp_earned': totalXpEarned,
        'completed_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('Error marking lesson as completed: $e');
      // Don't throw - completion saving is non-critical
    }
  }
}

