import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_preferences_model.dart';
import '../config/supabase_config.dart';

class UserPreferencesService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Check if user has preferences saved
  static Future<bool> hasPreferences(String userId) async {
    if (SupabaseConfig.isDemoMode) return false;

    try {
      final response = await _client
          .from('user_preferences')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking preferences: $e');
      return false;
    }
  }

  /// Get user preferences
  static Future<UserPreferences?> getPreferences(String userId) async {
    if (SupabaseConfig.isDemoMode) return null;

    try {
      final response = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return UserPreferences.fromJson(response);
    } catch (e) {
      print('Error fetching preferences: $e');
      return null;
    }
  }

  /// Save or update user preferences
  static Future<UserPreferences> savePreferences({
    required String userId,
    required String preferredLanguage,
    required String proficiencyLevel,
    required List<String> learningReasons,
    required int dailyGoalMinutes,
  }) async {
    if (SupabaseConfig.isDemoMode) {
      // Return mock data for demo mode
      return UserPreferences(
        id: 'demo-id',
        userId: userId,
        preferredLanguage: preferredLanguage,
        proficiencyLevel: proficiencyLevel,
        learningReasons: learningReasons,
        dailyGoalMinutes: dailyGoalMinutes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    try {
      // Check if preferences exist
      final existing = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final data = {
        'user_id': userId,
        'preferred_language': preferredLanguage,
        'proficiency_level': proficiencyLevel,
        'learning_reasons': learningReasons,
        'daily_goal_minutes': dailyGoalMinutes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (existing != null) {
        // Update existing
        final response = await _client
            .from('user_preferences')
            .update(data)
            .eq('user_id', userId)
            .select()
            .single();

        return UserPreferences.fromJson(response);
      } else {
        // Insert new
        final response = await _client
            .from('user_preferences')
            .insert(data)
            .select()
            .single();

        return UserPreferences.fromJson(response);
      }
    } catch (e) {
      print('Error saving preferences: $e');
      rethrow;
    }
  }

  /// Update specific preference fields
  static Future<UserPreferences?> updatePreferences({
    required String userId,
    String? preferredLanguage,
    String? proficiencyLevel,
    List<String>? learningReasons,
    int? dailyGoalMinutes,
  }) async {
    if (SupabaseConfig.isDemoMode) return null;

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (preferredLanguage != null) {
        updates['preferred_language'] = preferredLanguage;
      }
      if (proficiencyLevel != null) {
        updates['proficiency_level'] = proficiencyLevel;
      }
      if (learningReasons != null) {
        updates['learning_reasons'] = learningReasons;
      }
      if (dailyGoalMinutes != null) {
        updates['daily_goal_minutes'] = dailyGoalMinutes;
      }

      final response = await _client
          .from('user_preferences')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .maybeSingle();

      if (response == null) return null;
      return UserPreferences.fromJson(response);
    } catch (e) {
      print('Error updating preferences: $e');
      return null;
    }
  }
}

