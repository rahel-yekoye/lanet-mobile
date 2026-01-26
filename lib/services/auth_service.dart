// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../models/user_model.dart' as app_model;
import 'supabase_service.dart';
import '../config/supabase_config.dart';

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
    if (SupabaseConfig.isDemoMode) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_userKey) != null;
    }
    final session = _client.auth.currentSession;
    return session != null;
  }

  // Login user
  static Future<app_model.User> login(String email, String password) async {
    try {
      developer
          .log('AuthService.login: Attempting to sign in with email: $email');
      if (SupabaseConfig.isDemoMode) {
        final name = email.split('@').first;
        final userData = {
          'id': 'demo-$email',
          'name': name.isNotEmpty ? name : 'Demo User',
          'email': email,
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': DateTime.now().toIso8601String(),
          'dailyGoal': 5,
          'dailyXpEarned': 0,
          'settings': {},
        };
        await _saveAuthData('', userData);
        return app_model.User.fromJson(userData);
      }
      final normalizedEmail = email.trim().toLowerCase();
      final user = await SupabaseService.signIn(normalizedEmail, password);
      developer.log(
          'AuthService.login: Sign in response received: ${user != null ? "Success" : "Null user"}');
      if (user == null) {
        throw Exception('Invalid email or password.');
      }
      
      // Wait a moment for the session to be fully established and user record to be created
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Fetch user data - try multiple times if needed
      Map<String, dynamic>? userData;
      int retries = 3;
      while (userData == null && retries > 0) {
        userData = await SupabaseService.fetchUserData();
        if (userData == null && retries > 1) {
          developer.log('AuthService.login: User data not found, retrying... ($retries attempts left)');
          await Future.delayed(const Duration(milliseconds: 300));
        }
        retries--;
      }
      if (userData != null) {
        await _saveAuthData('', userData);
        return app_model.User.fromJson(userData);
      } else {
        final fallbackData = {
          'id': user.id,
          'name': '',
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': DateTime.now().toIso8601String(),
          'dailyGoal': 5,
          'dailyXpEarned': 0,
          'settings': {},
        };
        await _saveAuthData('', fallbackData);
        return app_model.User.fromJson(fallbackData);
      }
    } catch (e) {
      developer.log('Login error: $e');
      developer.log('Error type: ${e.runtimeType}');

      final msg = e.toString();
      if (msg.contains('AuthRetryableFetchException') ||
          msg.contains('Failed to fetch') ||
          msg.contains('ClientException') ||
          msg.contains('SocketException') ||
          msg.contains('connection timed out') ||
          msg.contains('Connection closed') ||
          msg.contains('handshake exception') ||
          msg.contains('certificate verify failed')) {
        throw Exception(
            'Network issue. Please check your internet connection and try again. If the problem persists, contact support.');
      }
      if (msg.contains('Invalid login credentials') ||
          msg.contains('Invalid credentials') ||
          msg.contains('400')) {
        throw Exception(
            'Invalid email or password. Please check your credentials and try again.');
      }
      if (msg.contains('429')) {
        throw Exception(
            'Too many requests. Please wait a moment and try again.');
      }

      // Re-throw the original error for better debugging
      developer.log('Re-throwing original error: $e');
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
    String? role,
  }) async {
    try {
      developer.log(
          'AuthService.register: Attempting to sign up with email: $email');
      if (SupabaseConfig.isDemoMode) {
        final userData = {
          'id': 'demo-$email',
          'name': name,
          'email': email,
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': DateTime.now().toIso8601String(),
          'dailyGoal': 5,
          'dailyXpEarned': 0,
          'settings': {},
        };
        await _saveAuthData('', userData);
        return app_model.User.fromJson(userData);
      }
      final normalizedEmail = email.trim().toLowerCase();
      final created =
          await SupabaseService.signUp(normalizedEmail, password, name: name, role: role);
      final user = created ??
          await SupabaseService.signIn(normalizedEmail, password);
      developer.log(
          'AuthService.register: Sign up response received: ${user != null ? "Success" : "Null user"}');
      if (user == null) throw Exception('Registration failed');
      final userData = await SupabaseService.fetchUserData();
      if (userData != null) {
        await _saveAuthData('', userData);
        return app_model.User.fromJson(userData);
      } else {
        final fallbackData = {
          'id': user.id,
          'name': name,
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': DateTime.now().toIso8601String(),
          'dailyGoal': 5,
          'dailyXpEarned': 0,
          'settings': {},
        };
        await _saveAuthData('', fallbackData);
        return app_model.User.fromJson(fallbackData);
      }
    } catch (e) {
      developer.log('Registration error: $e');

      final msg = e.toString();
      if (msg.contains('AuthRetryableFetchException') ||
          msg.contains('Failed to fetch') ||
          msg.contains('ClientException') ||
          msg.contains('SocketException') ||
          msg.contains('connection timed out') ||
          msg.contains('Connection closed') ||
          msg.contains('handshake exception') ||
          msg.contains('certificate verify failed')) {
        throw Exception(
            'Network issue. Please check your internet connection and try again. If the problem persists, contact support.');
      }
      if (msg.contains('429')) {
        throw Exception(
            'Too many requests. Please wait a moment and try again.');
      }
      if (msg.contains('400') || msg.contains('409')) {
        throw Exception(
            'Registration failed. This email may already be registered or the data is invalid.');
      }

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
      final userData = await SupabaseService.fetchUserData();
      if (userData != null) {
        return app_model.User.fromJson(userData);
      } else {
        final fallbackData = {
          'id': user.id,
          'name': '',
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': DateTime.now().toIso8601String(),
          'dailyGoal': 5,
          'dailyXpEarned': 0,
          'settings': {},
        };
        return app_model.User.fromJson(fallbackData);
      }
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
      if (SupabaseConfig.isDemoMode) {
        final current = await getUserData() ?? {};
        if (name != null) current['name'] = name;
        if (language != null) current['language'] = language;
        if (level != null) current['level'] = level;
        if (reason != null) current['reason'] = reason;
        if (dailyGoal != null) {
          current['daily_goal'] = dailyGoal;
          current['dailyGoal'] = dailyGoal;
        }
        if (onboardingCompleted != null) {
          current['onboarding_completed'] = onboardingCompleted;
          current['onboardingCompleted'] = onboardingCompleted;
        }
        await _saveAuthData('', current);
        return app_model.User.fromJson(current);
      }
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }
      await SupabaseService.updateUserData(
        name: name,
        language: language,
        level: level,
        reason: reason,
        dailyGoal: dailyGoal,
        onboardingCompleted: onboardingCompleted,
      );
      final userData = await SupabaseService.fetchUserData();
      if (userData != null) {
        await _saveAuthData('', userData);
        return app_model.User.fromJson(userData);
      } else {
        final fallbackData = {
          'id': user.id,
          'name': name ?? '',
          'xp': 0,
          'level': 1,
          'streak': 0,
          'lastActiveDate': DateTime.now().toIso8601String(),
          'dailyGoal': dailyGoal ?? 5,
          'dailyXpEarned': 0,
          'settings': {},
        };
        await _saveAuthData('', fallbackData);
        return app_model.User.fromJson(fallbackData);
      }
    } catch (e) {
      developer.log('Update profile error: $e');
      rethrow;
    }
  }

  // Deprecated: Internal helper method replaced by SupabaseService.fetchUserData
  // Kept for reference but should not be used
  static Future<Map<String, dynamic>> _fetchUserProfile(String userId) async {
    // Forward to SupabaseService
    final data = await SupabaseService.fetchUserData();
    return data ?? {};
  }
  static Future<Map<String, dynamic>> fetchUserProfile(String userId) async {
    return await _fetchUserProfile(userId);
  }
}
