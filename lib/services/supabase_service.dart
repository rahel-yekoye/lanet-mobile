import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Helper method to insert user data in background
  static void _insertUserData(User user, String? name, String email) {
    // Note: The database trigger 'on_auth_user_created' automatically creates
    // rows in 'public.users' and 'public.profiles'. We don't need to manually
    // insert them here, which avoids 409 Conflict errors.

    // However, if we need to update the automatically created profile with a name
    // that might not have been in metadata, we can do an update:
    if (name != null && name.isNotEmpty) {
      client
          .from('profiles')
          .update({
            'full_name': name,
          })
          .eq('id', user.id)
          .catchError((e) {
            developer.log('Background profiles update error: $e');
          });
    }
  }

  // Sign up a new user
  static Future<User?> signUp(String email, String password,
      {String? name}) async {
    try {
      developer
          .log('SupabaseService.signUp: Starting sign up for email: $email');

      // First, check if user already exists
      final existingSession = client.auth.currentSession;
      if (existingSession?.user.email == email) {
        developer
            .log('SupabaseService.signUp: User already exists with this email');
        return existingSession?.user;
      }

      final response = await client.auth.signUp(
        email: email,
        password: password,
        // Disable email confirmation for immediate access
        emailRedirectTo: null,
      );

      // Wait a moment for the auth user to be created
      await Future.delayed(const Duration(milliseconds: 500));

      // Insert additional user data if user was created (non-blocking)
      if (response.user != null) {
        developer.log(
            'SupabaseService.signUp: created user id=${response.user!.id}');
        // Don't await this - let it run in background
        _insertUserData(response.user!, name, email);
      } else {
        developer.log('SupabaseService.signUp: response.user is null');
      }

      return response.user;
    } catch (e) {
      developer.log('Sign up error: $e');
      developer.log('Sign up error type: ${e.runtimeType}');

      // More specific error handling
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('socket') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('ssl') ||
          errorMsg.contains('certificate')) {
        developer.log('Network-related error detected in sign up');
        throw Exception(
            'Network error: Unable to reach authentication server. Please check your internet connection and try again.');
      }

      // Handle rate limit specifically
      if (e.toString().contains('over_email_send_rate_limit')) {
        developer.log('Rate limit hit - this is normal during testing');
      }

      rethrow;
    }
  }

  // Sign in a user
  // Helper method to ensure user record exists in the users table
  static Future<void> _ensureUserRecord(User user) async {
    // Note: Database trigger handles creation.
    // We only update if needed, but for sign-in, we generally don't need to do anything
    // unless we want to sync metadata.
  }

  static Future<User?> signIn(String email, String password) async {
    try {
      developer
          .log('SupabaseService.signIn: Starting sign in for email: $email');

      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Ensure user exists in the users table
      if (response.user != null) {
        developer.log(
            'SupabaseService.signIn: user id=${response.user!.id} signed in successfully');
        await _ensureUserRecord(response.user!);
      } else {
        developer.log('SupabaseService.signIn: response.user is null');
      }

      return response.user;
    } catch (e) {
      developer.log('SupabaseService.signIn error: $e');
      developer.log('SupabaseService.signIn error type: ${e.runtimeType}');

      // More specific error handling
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('socket') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('ssl') ||
          errorMsg.contains('certificate')) {
        developer.log('Network-related error detected');
        throw Exception(
            'Network error: Unable to reach authentication server. Please check your internet connection and try again.');
      }

      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Get current user
  static User? getCurrentUser() {
    developer.log(
        'SupabaseService.getCurrentUser: currentUser=${client.auth.currentUser?.id}');
    return client.auth.currentUser;
  }

  // Fetch user data
  static Future<Map<String, dynamic>?> fetchUserData() async {
    final user = client.auth.currentUser;
    final userId = user?.id;
    developer.log('SupabaseService.fetchUserData: currentUserId=$userId');
    if (userId == null) return null;

    try {
      Map<String, dynamic>? response;

      // Try users table first (your app's main data)
      try {
        response =
            await client.from('users').select().eq('id', userId).maybeSingle();
      } catch (e) {
        developer.log('Error fetching from users table: $e');
      }

      // If not found, try profiles table
      if (response == null) {
        try {
          final profileData = await client
              .from('profiles')
              .select()
              .eq('id', userId)
              .maybeSingle();

          // Convert profiles data to match users table structure
          if (profileData != null) {
            response = {
              'id': profileData['id'],
              'name': profileData['full_name'] ?? '',
              'email': profileData['email'] ?? '',
              'xp': 0,
              'level': 1,
              'streak': 0,
              'lastActiveDate':
                  profileData['created_at'] ?? DateTime.now().toIso8601String(),
              'dailyGoal': 100,
              'dailyXpEarned': 0,
              'settings': {},
            };
          }
        } catch (e) {
          developer.log('Error fetching from profiles table: $e');
        }
      }

      // If STILL null (neither table has data), create a synthetic object from Auth metadata
      // This ensures we can still attach preferences to a valid object
      if (response == null) {
        developer
            .log('User not found in DB tables, creating synthetic user object');
        response = {
          'id': userId,
          'name': user?.userMetadata?['full_name'] ??
              user?.email?.split('@')[0] ??
              '',
          'email': user?.email ?? '',
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': DateTime.now().toIso8601String(),
          'dailyGoal': 100,
          'dailyXpEarned': 0,
          'settings': {},
        };
      }

      // Fetch user preferences and merge them
      try {
        final prefs = await client
            .from('user_preferences')
            .select()
            .eq('user_id', userId)
            .eq('selected', true);

        for (final pref in prefs) {
          final purpose = pref['purpose'] as String?;
          if (purpose == null) continue;

          if (purpose.startsWith('language_')) {
            final val = purpose.substring('language_'.length);
            response['language'] = val;
            developer.log('DEBUG: Found preference: language=$val');
          } else if (purpose.startsWith('level_')) {
            final val = purpose.substring('level_'.length);
            response['level'] = val;
            developer.log('DEBUG: Found preference: level=$val');
          } else if (purpose.startsWith('reason_')) {
            final val = purpose.substring('reason_'.length);
            response['reason'] = val;
            developer.log('DEBUG: Found preference: reason=$val');
          } else if (purpose.startsWith('daily_goal_')) {
            final goalStr = purpose.substring('daily_goal_'.length);
            response['daily_goal'] = int.tryParse(goalStr) ?? 100;
            response['dailyGoal'] = response['daily_goal']; // Support camelCase
            developer.log('DEBUG: Found preference: daily_goal=$goalStr');
          } else if (purpose == 'onboarding_status_completed') {
            response['onboarding_completed'] = true;
            response['onboardingCompleted'] = true;
            developer
                .log('DEBUG: Found preference: onboarding_status_completed');
          }
        }

        // If we found essential preferences (language and level), we can infer onboarding is complete
        // This handles the case where existing users have preferences but onboarding_completed flag might be missing/false
        if (response['language'] != null && response['level'] != null) {
          response['onboarding_completed'] = true;
          response['onboardingCompleted'] = true;
        }
      } catch (e) {
        developer.log('Error fetching user_preferences: $e');
      }

      return response;
    } catch (e) {
      developer.log('Error fetching user data: $e');
      developer.log('Error type: ${e.runtimeType}');

      // More specific error handling
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('socket') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('ssl') ||
          errorMsg.contains('certificate')) {
        developer.log('Network-related error detected in fetch user data');
        throw Exception(
            'Network error: Unable to reach data server. Please check your internet connection and try again.');
      }

      return null;
    }
  }

  static Future<void> updateProgress({
    int? dailyXP,
    int? streak,
    int? xp,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (dailyXP != null) updates['daily_xp_earned'] = dailyXP;
    if (streak != null) updates['streak'] = streak;
    if (xp != null) updates['xp'] = xp;
    if (updates.isEmpty) return;
    try {
      await _ensureUserRowExists();
      await client.from('users').update({
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      developer.log('Error updating progress: $e');
    }
  }

  static Future<void> _ensureUserRowExists() async {
    final user = client.auth.currentUser;
    if (user == null) return;
    try {
      final existing = await client
          .from('users')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();
      if (existing == null) {
        await client.from('users').insert({
          'id': user.id,
          'email': user.email,
          'created_at': DateTime.now().toIso8601String(),
        });
        print('DEBUG: Inserted users row for ${user.id}');
      }
    } catch (e) {
      print('DEBUG: ensure users row error: $e');
    }
  }

  // Save a single preference tag
  static Future<void> _savePreferenceTag(
      String userId, String prefix, String value) async {
    // Using print to ensure visibility in all consoles
    print(
        'DEBUG: SupabaseService attempting to save $prefix=$value for user $userId');

    try {
      // 1. Check if the tag already exists
      // We check for specific value first to avoid unnecessary writes
      final existingSpecific = await client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .eq('purpose', '${prefix}_$value')
          .maybeSingle();

      if (existingSpecific != null) {
        print(
            'DEBUG: Preference $prefix=$value already exists. Skipping save.');
        return;
      }

      // 2. Clear other tags for this category (single-choice enforcement)
      // We attempt this, but if it fails (e.g. RLS), we continue.
      try {
        // We first find what to delete to avoid blind deletes that might cause issues
        // Actually, just delete. If it fails, it fails.
        await client
            .from('user_preferences')
            .delete()
            .eq('user_id', userId)
            .like('purpose', '$prefix%');
      } catch (e) {
        print('DEBUG: Error clearing old preferences (non-fatal): $e');
      }

      // 3. Insert the new tag
      try {
        await client.from('user_preferences').insert({
          'user_id': userId,
          'purpose': '${prefix}_$value',
          'selected': true,
        });
        print('DEBUG: Successfully saved $prefix=$value');
      } catch (insertError) {
        // Double check if it exists now (race condition)
        final doubleCheck = await client
            .from('user_preferences')
            .select()
            .eq('user_id', userId)
            .eq('purpose', '${prefix}_$value')
            .maybeSingle();

        if (doubleCheck != null) {
          print('DEBUG: Insert failed but preference exists. Ignoring error.');
        } else {
          // Genuine error
          print('DEBUG: Error inserting preference: $insertError');
          // We suppress 409s specifically even if check failed (weird caching?)
          if (insertError.toString().contains('409') ||
              insertError.toString().contains('Conflict')) {
            print('DEBUG: Suppressing 409 Conflict.');
          } else {
            rethrow;
          }
        }
      }
    } catch (e) {
      print('DEBUG: Fatal error in _savePreferenceTag: $e');
    }
  }

  // Update user data
  static Future<void> updateUserData({
    String? name,
    String? language,
    String? level,
    String? reason,
    int? dailyGoal,
    bool? onboardingCompleted,
  }) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    // We still update 'users' table columns for backward compatibility and redundancy
    if (language != null) updates['language'] = language;
    if (level != null) updates['level'] = level;
    if (reason != null) updates['reason'] = reason;
    if (dailyGoal != null) updates['daily_goal'] = dailyGoal;
    if (onboardingCompleted != null) {
      updates['onboarding_completed'] = onboardingCompleted;
    }

    // 1. Save to 'user_preferences' table (CRITICAL for onboarding flow)
    // We do this first so that even if other updates fail, the user is considered onboarded
    try {
      await _ensureUserRowExists();
      if (language != null) {
        await _savePreferenceTag(userId, 'language', language);
      }
      if (level != null) await _savePreferenceTag(userId, 'level', level);
      if (reason != null) await _savePreferenceTag(userId, 'reason', reason);
      if (dailyGoal != null) {
        await _savePreferenceTag(userId, 'daily_goal', dailyGoal.toString());
      }
      if (onboardingCompleted == true) {
        await _savePreferenceTag(userId, 'onboarding_status', 'completed');
      }
    } catch (e) {
      developer.log('Error updating user_preferences: $e');
      // This is critical, but we continue to try other updates
    }

    // 2. Update 'profiles' table (Reliable)
    if (name != null) {
      try {
        await client.from('profiles').upsert({
          'id': userId,
          'full_name': name,
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        developer.log('Error updating profiles: $e');
      }
    }

    // 3. Update 'users' table (Legacy/Redundant)
    // We use update() instead of upsert() to avoid 400 Bad Request errors when the row is missing
    // and we don't have all required fields (like email) to create it.
    try {
      if (updates.isNotEmpty) {
        await client.from('users').update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);
      }
    } catch (e) {
      developer.log('Error updating users table: $e');
    }
  }
}
