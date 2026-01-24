import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;

class SupabaseService {
  static SupabaseClient get client => Supabase.instance.client;

  // Helper method to insert user data in background
  static void _insertUserData(User user, String? name, String email) {
    // Avoid writing to the auth-managed `users` table (it requires password_hash).
    // Use a separate `profiles` table for app-specific user metadata.
    // Run in background without awaiting.
    client.from('profiles').insert({
      'id': user.id,
      'full_name': name ?? '',
      'email': email,
      'created_at': DateTime.now().toIso8601String(),
    }).catchError((e) async {
      developer.log('Background profiles insert error: $e');
      // Try upsert as fallback into profiles
      try {
        await client.from('profiles').upsert({
          'id': user.id,
          'full_name': name ?? '',
          'email': email,
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (upsertError) {
        developer.log('Background profiles upsert error: $upsertError');
      }
    });
  }

  // Sign up a new user
  static Future<User?> signUp(String email, String password, {String? name}) async {
    try {
      // First, check if user already exists
      final existingSession = client.auth.currentSession;
      if (existingSession?.user?.email == email) {
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
        developer.log('SupabaseService.signUp: created user id=${response.user!.id}');
        // Don't await this - let it run in background
        _insertUserData(response.user!, name, email);
      } else {
        developer.log('SupabaseService.signUp: response.user is null');
      }
      
      return response.user;
    } catch (e) {
      print('Sign up error: $e');
      print('Error type: ${e.runtimeType}');
      // Handle rate limit specifically
      if (e.toString().contains('over_email_send_rate_limit')) {
        print('Rate limit hit - this is normal during testing');
      }
      return null;
    }
  }

  // Sign in a user
  // Helper method to ensure user record exists in the users table
  static Future<void> _ensureUserRecord(User user) async {
    try {
      // Prefer upserting into `profiles` for app metadata.
      await client.from('profiles').upsert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'] ?? '',
        'email': user.email ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      developer.log('Error ensuring user record in profiles: $e');
      // As a last-resort, log the error and skip creating a record to avoid
      // violating constraints on the auth.users table (e.g. password_hash NOT NULL).
    }
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
      print('Sign in error: $e');
      // Handle rate limit specifically
      if (e.toString().contains('over_email_send_rate_limit')) {
        print('Rate limit hit during sign in - this is normal');
      }
      return null;
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
      
      return response;
    } catch (e) {
      print('Error fetching user data: $e');
      return null;
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
    if (language != null) updates['language'] = language;
    if (level != null) updates['level'] = level;
    if (reason != null) updates['reason'] = reason;
    if (dailyGoal != null) updates['dailyGoal'] = dailyGoal;
    if (onboardingCompleted != null) updates['onboarding_completed'] = onboardingCompleted;

    try {
      await client
          .from('users')
          .update(updates)
          .eq('id', userId);
      
      // Also update profiles table if name changed
      if (name != null) {
        await client
            .from('profiles')
            .update({'full_name': name})
            .eq('id', userId);
      }
    } catch (e) {
      print('Error updating user data: $e');
    }
  }
}