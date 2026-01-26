import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Helper method to insert user data in background
  static void _insertUserData(User user, String? name, String email, {String? role}) async {
    // Note: The database trigger 'on_auth_user_created' automatically creates
    // rows in 'public.users' and 'public.profiles'. We don't need to manually
    // insert them here, which avoids 409 Conflict errors.

    // However, if we need to update the automatically created profile with a name
    // that might not have been in metadata, we can do an update:
    final updateData = <String, dynamic>{};
    if (name != null && name.isNotEmpty) {
      updateData['full_name'] = name;
    }
    if (role != null && role.isNotEmpty) {
      updateData['role'] = role;
    }
    
    if (updateData.isNotEmpty) {
      await client
          .from('profiles')
          .update(updateData)
          .eq('id', user.id)
          .catchError((e) {
            developer.log('Background profiles update error: $e');
          });
    }
  }

  // Sign up a new user
  static Future<User?> signUp(String email, String password,
      {String? name, String? role}) async {
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
        data: name != null && name.isNotEmpty ? {'full_name': name} : null,
        emailRedirectTo: null,
      );

      // Wait a moment for the auth user to be created
      await Future.delayed(const Duration(milliseconds: 500));

      // Insert additional user data if user was created (non-blocking)
      if (response.user != null) {
        developer.log(
            'SupabaseService.signUp: created user id=${response.user!.id}');
        // Don't await this - let it run in background
        _insertUserData(response.user!, name, email, role: role);
      } else {
        developer.log('SupabaseService.signUp: response.user is null');
      }

      return response.user;
    } catch (e) {
      developer.log('Sign up error: $e');
      developer.log('Sign up error type: ${e.runtimeType}');
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
    developer.log(
        'SupabaseService.getCurrentUser: currentUser=${client.auth.currentUser?.id}');
    return client.auth.currentUser;
  }

  // Fetch user data
  static Future<Map<String, dynamic>?> fetchUserData() async {
    // Ensure we have a valid session
    final session = client.auth.currentSession;
    if (session == null) {
      developer.log('SupabaseService.fetchUserData: No active session');
      return null;
    }
    
    final user = client.auth.currentUser;
    final userId = user?.id;
    developer.log('SupabaseService.fetchUserData: currentUserId=$userId, sessionExists=${session != null}');
    if (userId == null) {
      developer.log('SupabaseService.fetchUserData: User ID is null');
      return null;
    }

    try {
      Map<String, dynamic>? response;

      // Try users table first (your app's main data with XP, streak, etc.)
      try {
        final usersData = await client.from('users').select().eq('id', userId).maybeSingle();
        if (usersData != null) {
          // Map users table data properly - preserve all actual values
          response = {
            'id': usersData['id'] ?? userId,
            'name': usersData['name'] ?? usersData['full_name'] ?? '',
            'email': usersData['email'] ?? user?.email ?? '',
            // CRITICAL: Use actual values from database, not defaults
            'xp': usersData['xp'] ?? 0,
            'level': usersData['level'] ?? 1,
            'streak': usersData['streak'] ?? 0,
            'lastActiveDate': usersData['lastActiveDate'] ?? 
                             usersData['last_active_date'] ?? 
                             DateTime.now().toIso8601String(),
            'dailyGoal': usersData['dailyGoal'] ?? usersData['daily_goal'] ?? 5,
            'daily_goal': usersData['daily_goal'] ?? usersData['dailyGoal'] ?? 5,
            'dailyXpEarned': usersData['dailyXpEarned'] ?? usersData['daily_xp_earned'] ?? 0,
            'daily_xp_earned': usersData['daily_xp_earned'] ?? usersData['dailyXpEarned'] ?? 0,
            'settings': usersData['settings'] ?? {},
            'onboarding_completed': usersData['onboarding_completed'] ?? usersData['onboardingCompleted'] ?? false,
            'onboardingCompleted': usersData['onboardingCompleted'] ?? usersData['onboarding_completed'] ?? false,
          };
          developer.log('DEBUG: Fetched user data from users table: xp=${response['xp']}, streak=${response['streak']}, daily_xp=${response['dailyXpEarned']}');
        }
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
              'email': profileData['email'] ?? user?.email ?? '',
              'xp': 0,
              'level': 1,
              'streak': 0,
              'lastActiveDate':
                  profileData['created_at'] ?? DateTime.now().toIso8601String(),
              'dailyGoal': 5,
              'daily_goal': 5,
              'dailyXpEarned': 0,
              'daily_xp_earned': 0,
              'settings': {},
            };
          }
        } catch (e) {
          developer.log('Error fetching from profiles table: $e');
        }
      }

      // If STILL null (neither table has data), try to ensure user record exists
      if (response == null) {
        developer.log('User not found in DB tables, attempting to create user record');
        try {
          // Try to ensure user row exists
          await _ensureUserRowExists();
          // Wait a moment for the record to be created
          await Future.delayed(const Duration(milliseconds: 300));
          // Try fetching again
          final retryData = await client.from('users').select().eq('id', userId).maybeSingle();
          if (retryData != null) {
            response = {
              'id': retryData['id'] ?? userId,
              'name': retryData['name'] ?? retryData['full_name'] ?? '',
              'email': retryData['email'] ?? user?.email ?? '',
              'xp': retryData['xp'] ?? 0,
              'level': retryData['level'] ?? 1,
              'streak': retryData['streak'] ?? 0,
              'lastActiveDate': retryData['lastActiveDate'] ?? 
                               retryData['last_active_date'] ?? 
                               DateTime.now().toIso8601String(),
              'dailyGoal': retryData['dailyGoal'] ?? retryData['daily_goal'] ?? 5,
              'daily_goal': retryData['daily_goal'] ?? retryData['dailyGoal'] ?? 5,
              'dailyXpEarned': retryData['dailyXpEarned'] ?? retryData['daily_xp_earned'] ?? 0,
              'daily_xp_earned': retryData['daily_xp_earned'] ?? retryData['dailyXpEarned'] ?? 0,
              'settings': retryData['settings'] ?? {},
              'onboarding_completed': retryData['onboarding_completed'] ?? retryData['onboardingCompleted'] ?? false,
              'onboardingCompleted': retryData['onboardingCompleted'] ?? retryData['onboarding_completed'] ?? false,
            };
            developer.log('User record created and fetched successfully');
          }
        } catch (e) {
          developer.log('Error ensuring user record exists: $e');
        }
        
        // If still null, create a synthetic object from Auth metadata
        if (response == null) {
          developer.log('User not found in DB tables, creating synthetic user object');
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
            'dailyGoal': 5,
            'daily_goal': 5,
            'dailyXpEarned': 0,
            'daily_xp_earned': 0,
            'settings': {},
          };
        }
      }

      // Fetch user preferences and merge them
      // Handle both new structure (preferred_language, proficiency_level) and old structure (purpose field)
      try {
        // Try new structure first (preferred_language, proficiency_level columns)
        try {
          final newPrefs = await client
              .from('user_preferences')
              .select()
              .eq('user_id', userId)
              .maybeSingle();

          if (newPrefs != null) {
            // New structure with direct columns
            if (newPrefs['preferred_language'] != null) {
              response['language'] = newPrefs['preferred_language'];
              developer.log('DEBUG: Found preference (new structure): language=${newPrefs['preferred_language']}');
            }
            if (newPrefs['proficiency_level'] != null) {
              response['level'] = newPrefs['proficiency_level'];
              developer.log('DEBUG: Found preference (new structure): level=${newPrefs['proficiency_level']}');
            }
            if (newPrefs['daily_goal_minutes'] != null) {
              final goal = newPrefs['daily_goal_minutes'] is int 
                  ? newPrefs['daily_goal_minutes'] 
                  : int.tryParse(newPrefs['daily_goal_minutes'].toString()) ?? 5;
              response['daily_goal'] = goal;
              response['dailyGoal'] = goal;
              developer.log('DEBUG: Found preference (new structure): daily_goal=$goal');
            }
            if (newPrefs['learning_reasons'] != null) {
              final reasons = newPrefs['learning_reasons'];
              if (reasons is List && reasons.isNotEmpty) {
                response['reason'] = reasons.first.toString();
                developer.log('DEBUG: Found preference (new structure): reason=${reasons.first}');
              }
            }
            // If we have language and level, onboarding is complete
            if (response['language'] != null && response['level'] != null) {
              response['onboarding_completed'] = true;
              response['onboardingCompleted'] = true;
            }
          }
        } catch (e) {
          developer.log('Error fetching new structure preferences: $e');
        }

        // Also try old structure (purpose field with selected = true)
        try {
          final oldPrefs = await client
              .from('user_preferences')
              .select()
              .eq('user_id', userId)
              .eq('selected', true);

          if (oldPrefs != null && (oldPrefs as List).isNotEmpty) {
            for (final pref in oldPrefs) {
              final purpose = pref['purpose'] as String?;
              if (purpose == null) continue;

              if (purpose.startsWith('language_')) {
                final val = purpose.substring('language_'.length);
                response['language'] = val;
                developer.log('DEBUG: Found preference (old structure): language=$val');
              } else if (purpose.startsWith('level_')) {
                final val = purpose.substring('level_'.length);
                response['level'] = val;
                developer.log('DEBUG: Found preference (old structure): level=$val');
              } else if (purpose.startsWith('reason_')) {
                final val = purpose.substring('reason_'.length);
                response['reason'] = val;
                developer.log('DEBUG: Found preference (old structure): reason=$val');
              } else if (purpose.startsWith('daily_goal_')) {
                final goalStr = purpose.substring('daily_goal_'.length);
                response['daily_goal'] = int.tryParse(goalStr) ?? 5;
                response['dailyGoal'] = response['daily_goal']; // Support camelCase
                developer.log('DEBUG: Found preference (old structure): daily_goal=$goalStr');
              } else if (purpose == 'onboarding_status_completed') {
                response['onboarding_completed'] = true;
                response['onboardingCompleted'] = true;
                developer
                    .log('DEBUG: Found preference (old structure): onboarding_status_completed');
              }
            }

            // If we found essential preferences (language and level), we can infer onboarding is complete
            if (response['language'] != null && response['level'] != null) {
              response['onboarding_completed'] = true;
              response['onboardingCompleted'] = true;
            }
          }
        } catch (e) {
          developer.log('Error fetching old structure preferences: $e');
        }
      } catch (e) {
        developer.log('Error fetching user_preferences: $e');
      }

      developer.log('DEBUG: Final user data: xp=${response['xp']}, streak=${response['streak']}, language=${response['language']}, level=${response['level']}');
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
        developer.log('Inserted users row for ${user.id}');
      }
    } catch (e) {
      developer.log('ensure users row error: $e');
    }
  }
 
  static Future<void> _savePreferenceTag(
      String userId, String prefix, String value) async {
    try {
      await client
          .from('user_preferences')
          .update({'selected': false})
          .eq('user_id', userId)
          .like('purpose', '$prefix%');
    } catch (e) {}
 
    final purpose = '${prefix}_$value';
    try {
      final existing = await client
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .eq('purpose', purpose)
          .maybeSingle();
      if (existing != null) {
        await client
            .from('user_preferences')
            .update({'selected': true})
            .eq('id', existing['id']);
      } else {
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
      // Don't throw - this is a non-critical update during onboarding
      // The user_preferences table is the source of truth
      // A 400 error here usually means the row doesn't exist, which is fine during onboarding
      final errorMsg = e.toString();
      if (errorMsg.contains('400') || errorMsg.contains('not found') || errorMsg.contains('does not exist')) {
        developer.log('Users table row does not exist for user $userId - this is okay during onboarding');
      } else {
        developer.log('Error updating users table (non-critical): $e');
      }
    }
  }
}
