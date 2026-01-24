// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart' as app_model;
import 'supabase_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static SupabaseClient get _client => Supabase.instance.client;

  // Store authentication data
  static Future<void> _saveAuthData(
      String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_tokenKey, token),
      prefs.setString(_userKey, jsonEncode(userData)),
    ]);
  }

  // Get stored authentication token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get stored user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final session = _client.auth.currentSession;
    return session != null;
  }

  // Login user
  static Future<app_model.User> login(String email, String password) async {
    try {
      final user = await SupabaseService.signIn(email, password);
      if (user == null) {
        throw Exception('Invalid credentials');
      }
      
      // Fetch user data from database
      final userData = await _fetchUserProfile(user.id);
      
      // Save auth data locally
      await _saveAuthData('', userData);
      
      return app_model.User.fromJson(userData);
    } catch (e) {
      developer.log('Login error: $e');
      rethrow;
    }
  }

  // Register a new user
  static Future<app_model.User> register({
    required String name,
    required String email,
    required String password,
    String? language,
    String? level,
    String? reason,
    int? dailyGoal,
  }) async {
    try {
      final user = await SupabaseService.signUp(email, password, name: name);
      if (user == null) {
        throw Exception('Registration failed');
      }
      
      // Create initial user profile - NEW USERS should go through onboarding
      final userData = {
        'id': user.id,
        'name': name,
        'email': email,
        'xp': 0,
        'level': 1,
        'streak': 0,
        'lastActiveDate': DateTime.now().toIso8601String(),
        'dailyGoal': 100, // Default value
        'dailyXpEarned': 0,
        'settings': {},
        // Don't set onboarding fields yet - let user complete onboarding flow
        // 'language': language,
        // 'level': level,  
        // 'reason': reason,
        // 'dailyGoal': dailyGoal,
        // 'onboarding_completed': false,
      };
      
      // Save to users table with minimal data (forces onboarding)
      await _client.from('users').upsert({
        'id': user.id,
        'name': name,
        'email': email,
        'xp': 0,
        'level': 1,
        'streak': 0,
        'lastActiveDate': DateTime.now().toIso8601String(),
        'dailyGoal': 100,
        'dailyXpEarned': 0,
        'settings': '{}',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Also save to profiles table
      await _client.from('profiles').upsert({
        'id': user.id,
        'full_name': name,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      // Save auth data locally
      await _saveAuthData('', userData);
      
      return app_model.User.fromJson(userData);
    } catch (e) {
      developer.log('Registration error: $e');
      rethrow;
    }
  }

  // Logout user
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_userKey),
      ]);
    } catch (e) {
      developer.log('Logout error: $e');
      rethrow;
    }
  }

  // Get current user profile
  static Future<app_model.User> getCurrentUser() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }
      
      final userData = await _fetchUserProfile(user.id);
      return app_model.User.fromJson(userData);
    } catch (e) {
      developer.log('Get current user error: $e');
      rethrow;
    }
  }

  // Update user profile
  static Future<app_model.User> updateProfile({
    String? name,
    String? language,
    String? level,
    String? reason,
    int? dailyGoal,
    bool? onboardingCompleted,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }
      
      // Update profiles table
      final updates = <String, dynamic>{};
      if (name != null) updates['full_name'] = name;
      
      if (updates.isNotEmpty) {
        await _client.from('profiles').update(updates).eq('id', user.id);
      }
      
      // Update user data in users table (your app's main data)
      final userUpdates = <String, dynamic>{};
      if (name != null) userUpdates['name'] = name;
      if (language != null) userUpdates['language'] = language;
      if (level != null) userUpdates['level'] = level;
      if (reason != null) userUpdates['reason'] = reason;
      if (dailyGoal != null) userUpdates['dailyGoal'] = dailyGoal;
      if (onboardingCompleted != null) userUpdates['onboarding_completed'] = onboardingCompleted;
      
      if (userUpdates.isNotEmpty) {
        await _client.from('users').update(userUpdates).eq('id', user.id);
      }
      
      // Fetch updated user data
      final userData = await _fetchUserProfile(user.id);
      await _saveAuthData('', userData);
      
      return app_model.User.fromJson(userData);
    } catch (e) {
      developer.log('Update profile error: $e');
      rethrow;
    }
  }

  // Helper method to fetch user profile from Supabase
  static Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    try {
      // Try to get from users table first
      final userData = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (userData != null) {
        return userData;
      }
      
      // Fallback to profiles table
      final profileData = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (profileData != null) {
        return {
          'id': profileData['id'],
          'name': profileData['full_name'] ?? '',
          'email': profileData['email'] ?? '',
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': profileData['created_at'] ?? DateTime.now().toIso8601String(),
          'dailyGoal': 100,
          'dailyXpEarned': 0,
          'settings': {},
        };
      }
      
      // Return minimal user data if nothing found
      return {
        'id': userId,
        'name': '',
        'xp': 0,
        'level': 1,
        'streak': 0,
        'lastActiveDate': DateTime.now().toIso8601String(),
        'dailyGoal': 100,
        'dailyXpEarned': 0,
        'settings': {},
      };
    } catch (e) {
      developer.log('Error fetching user profile: $e');
      rethrow;
    }
  }
}