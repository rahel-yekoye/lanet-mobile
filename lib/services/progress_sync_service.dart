import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service to sync user progress with Supabase
class ProgressSyncService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Save completed category to Supabase
  static Future<void> saveCompletedCategory(String category) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Use upsert to handle both insert and update
      // Check if record exists first
      final existing = await _client
          .from('user_category_progress')
          .select('id')
          .eq('user_id', userId)
          .eq('category', category)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await _client
            .from('user_category_progress')
            .update({
              'completed': true,
              'completed_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('category', category);
      } else {
        // Insert new
        await _client.from('user_category_progress').insert({
          'user_id': userId,
          'category': category,
          'completed': true,
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving completed category to Supabase: $e');
      // Don't throw - allow local storage to continue working
    }
  }

  /// Fetch all completed categories from Supabase
  static Future<List<String>> getCompletedCategories() async {
    if (SupabaseConfig.isDemoMode) return [];

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _client
          .from('user_category_progress')
          .select('category')
          .eq('user_id', userId)
          .eq('completed', true);

      return (response as List)
          .map((item) => (item as Map<String, dynamic>)['category'] as String)
          .toList();
    } catch (e) {
      print('Error fetching completed categories from Supabase: $e');
      return [];
    }
  }

  /// Save session state to Supabase
  static Future<void> saveSession({
    required String category,
    required String screen,
    Map<String, dynamic>? additionalData,
  }) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Check if session exists
      final existing = await _client
          .from('user_sessions')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await _client
            .from('user_sessions')
            .update({
              'category': category,
              'screen': screen,
              'additional_data': additionalData ?? {},
              'last_active': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId);
      } else {
        // Insert new
        await _client.from('user_sessions').insert({
          'user_id': userId,
          'category': category,
          'screen': screen,
          'additional_data': additionalData ?? {},
          'last_active': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error saving session to Supabase: $e');
      // Don't throw - allow local storage to continue working
    }
  }

  /// Fetch session state from Supabase
  static Future<Map<String, dynamic>?> getSession() async {
    if (SupabaseConfig.isDemoMode) return null;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('user_sessions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;

      return {
        'category': response['category'] as String?,
        'screen': response['screen'] as String?,
        'timestamp': response['last_active'] as String?,
        'additionalData': response['additional_data'] as Map<String, dynamic>? ?? {},
      };
    } catch (e) {
      print('Error fetching session from Supabase: $e');
      return null;
    }
  }

  /// Clear all progress (for logout)
  static Future<void> clearProgress() async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Note: We don't delete progress, just clear the session
      // Progress should persist across logins
      await _client
          .from('user_sessions')
          .delete()
          .eq('user_id', userId);
    } catch (e) {
      print('Error clearing session from Supabase: $e');
    }
  }

  /// Sync local progress to Supabase (called on login)
  static Future<void> syncProgressToSupabase({
    required List<String> completedCategories,
    Map<String, dynamic>? session,
  }) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;

      // Sync completed categories
      for (final category in completedCategories) {
        await saveCompletedCategory(category);
      }

      // Sync session if provided
      if (session != null) {
        await saveSession(
          category: session['category'] as String? ?? '',
          screen: session['screen'] as String? ?? 'home',
          additionalData: session['additionalData'] as Map<String, dynamic>?,
        );
      }
    } catch (e) {
      print('Error syncing progress to Supabase: $e');
    }
  }
}

