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
      client.from('profiles').update({
        'full_name': name,
      }).eq('id', user.id).catchError((e) {
        developer.log('Background profiles update error: $e');
      });
    }
  }

  // Sign up a new user
  static Future<User?> signUp(String email, String password, {String? name}) async {
    try {
      // First, check if user already exists
      final existingSession = client.auth.currentSession;
      if (existingSession?.user.email == email) {
        return existingSession?.user;
      }
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: name != null && name.isNotEmpty ? {'full_name': name} : null,
        emailRedirectTo: null,
      );
      
      // Wait a moment for the auth user to be created
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Insert additional user data if user was created (non-blocking)
      if (response.user != null) {
        developer.log('SupabaseService.signUp: created user id=${response.user!.id}');
        // Don't await this - let it run in background
        _insertUserData(response.user!, name, email);
      } else {
        developer.log('SupabaseService.signUp: response.user is null');
      }
      
      return response.user;
    } catch (e) {
      developer.log('Sign up error: $e');
      if (e.toString().contains('over_email_send_rate_limit')) {
        developer.log('Rate limit hit during sign up');
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
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      // Ensure user exists in the users table
      if (response.user != null) {
        developer.log('SupabaseService.signIn: user id=${response.user!.id} signed in');
        await _ensureUserRecord(response.user!);
      } else {
        developer.log('SupabaseService.signIn: response.user null');
      }
      
      return response.user;
    } catch (e) {
      developer.log('Sign in error: $e');
      if (e.toString().contains('over_email_send_rate_limit')) {
        developer.log('Rate limit hit during sign in');
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
    developer.log('SupabaseService.getCurrentUser: currentUser=${client.auth.currentUser?.id}');
    return client.auth.currentUser;
  }

  // Fetch user data
  static Future<Map<String, dynamic>?> fetchUserData() async {
    final userId = client.auth.currentUser?.id;
    developer.log('SupabaseService.fetchUserData: currentUserId=$userId');
    if (userId == null) return null;

    try {
      // Try users table first (your app's main data)
      var response = await client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      // If not found, try profiles table
      if (response == null) {
        response = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        
        // Convert profiles data to match users table structure
        if (response != null) {
          response = {
            'id': response['id'],
            'name': response['full_name'] ?? '',
            'email': response['email'] ?? '',
            'xp': 0,
            'level': 1,
            'streak': 0,
            'lastActiveDate': response['created_at'] ?? DateTime.now().toIso8601String(),
            'dailyGoal': 100,
            'dailyXpEarned': 0,
            'settings': {},
          };
        }
      }
      
      // Fetch user preferences and merge them
      if (response != null) {
        try {
          final prefs = await client
              .from('user_preferences')
              .select()
              .eq('user_id', userId)
              .eq('selected', true);
          
          if (prefs is List) {
            for (final pref in prefs) {
              final purpose = pref['purpose'] as String?;
              if (purpose == null) continue;
              
              if (purpose.startsWith('language_')) {
                response['language'] = purpose.substring('language_'.length);
              } else if (purpose.startsWith('level_')) {
                response['level'] = purpose.substring('level_'.length);
              } else if (purpose.startsWith('reason_')) {
                response['reason'] = purpose.substring('reason_'.length);
              } else if (purpose.startsWith('daily_goal_')) {
                final goalStr = purpose.substring('daily_goal_'.length);
                response['daily_goal'] = int.tryParse(goalStr) ?? 100;
                response['dailyGoal'] = response['daily_goal']; // Support camelCase
              }
            }
            
            // If we found essential preferences (language and level), we can infer onboarding is complete
            // This handles the case where existing users have preferences but onboarding_completed flag might be missing/false
            if (response['language'] != null && response['level'] != null) {
               response['onboarding_completed'] = true;
               response['onboardingCompleted'] = true;
            }
          }
        } catch (e) {
          developer.log('Error fetching user_preferences: $e');
        }
      }
      
      return response;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
    }
  }

  // Save a single preference tag
  static Future<void> _savePreferenceTag(String userId, String prefix, String value) async {
    // 1. Unselect ANY existing tags for this category (prefix)
    // RLS "Users can update own preferences" allows this.
    try {
      await client
          .from('user_preferences')
          .update({'selected': false})
          .eq('user_id', userId)
          .like('purpose', '$prefix%');
    } catch (e) {
       // Ignore, table might be empty or update not needed
    }

    // 2. Set the new tag
    // We use a check-then-act pattern to work around potential RLS limitations on UPSERT
    // or missing DELETE permissions.
    final purpose = '${prefix}_$value';
    
    try {
      // Check if the specific tag already exists
      final existing = await client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .eq('purpose', purpose)
          .maybeSingle();
          
      if (existing != null) {
        // Update existing row to be selected
        await client
            .from('user_preferences')
            .update({'selected': true})
            .eq('id', existing['id']); 
      } else {
        // Insert new row
        await client.from('user_preferences').insert({
          'user_id': userId,
          'purpose': purpose,
          'selected': true,
        });
      }
    } catch (e) {
       developer.log('Error saving preference tag ($purpose): $e');
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
    if (onboardingCompleted != null) updates['onboarding_completed'] = onboardingCompleted;

    // 1. Save to 'user_preferences' table (CRITICAL for onboarding flow)
    // We do this first so that even if other updates fail, the user is considered onboarded
    try {
      if (language != null) await _savePreferenceTag(userId, 'language', language);
      if (level != null) await _savePreferenceTag(userId, 'level', level);
      if (reason != null) await _savePreferenceTag(userId, 'reason', reason);
      if (dailyGoal != null) await _savePreferenceTag(userId, 'daily_goal', dailyGoal.toString());
    } catch (e) {
      developer.log('Error updating user_preferences: $e');
      // This is critical, but we continue to try other updates
    }

    // 2. Update 'profiles' table (Reliable)
    if (name != null) {
      try {
        await client
            .from('profiles')
            .upsert({
              'id': userId,
              'full_name': name,
            });
      } catch (e) {
        developer.log('Error updating profiles: $e');
      }
    }

    // 3. Update 'users' table (Legacy/Redundant)
    // This often fails if the row is missing and name is null (not-null constraint),
    // so we wrap it separately and attempt a fallback.
    try {
      var upsertData = {
        'id': userId,
        ...updates,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await client
          .from('users')
          .upsert(upsertData);
    } catch (e) {
      developer.log('Error updating users table: $e');
      
      // Attempt recovery for the specific "null value in column name" error
      if (e.toString().contains('null value') && e.toString().contains('name') && !updates.containsKey('name')) {
        try {
          // Try to get name from auth metadata or just use a placeholder if absolutely needed to fix the row
          var metaName = client.auth.currentUser?.userMetadata?['full_name'];
          // Fallback if metadata name is also missing (e.g. legacy signup)
          metaName ??= 'Learner';
          
          if (metaName != null) {
            developer.log('Retrying users update with metadata name: $metaName');
            await client.from('users').upsert({
              'id': userId,
              ...updates,
              'name': metaName,
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (retryE) {
          developer.log('Retry updating users table failed: $retryE');
        }
      }
    }
  }
}
