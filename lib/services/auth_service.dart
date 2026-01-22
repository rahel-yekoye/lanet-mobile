// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'http://localhost:3000/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Helper method to get headers with auth token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

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
    final token = await getToken();
    if (token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/verify'),
        headers: await _getAuthHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      developer.log('Auth verification error: $e');
      return false;
    }
  }

  // Login user
  static Future<User> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'email': email,
          'password': password, // Send plain password (will be hashed by backend)
        }),
      );

      final responseData = _handleResponse(response);
      final userData = responseData['user'];
      
      // Filter the API response to match the User model expectations
      // Extract onboarding preferences separately to avoid conflicts
      final filteredUserData = {
        'id': userData['id'],
        'name': userData['name'],
        'xp': userData['xp'] ?? 0,
        'level': (userData['level'] is int) ? userData['level'] : 1, // Ensure it's an int, default to 1
        'streak': userData['streak'] ?? 0,
        'lastActiveDate': userData['created_at'],
        'dailyGoal': (userData['daily_goal'] is int) ? userData['daily_goal'] : ((userData['dailyGoal'] is int) ? userData['dailyGoal'] : 100),
        'dailyXpEarned': userData['dailyXpEarned'] ?? 0,
        'settings': userData['settings'] ?? {},
      };

      // Save auth data
      await _saveAuthData(
        responseData['token'],
        userData, // Store the original user data with all fields
      );

      return User.fromJson(filteredUserData);
    } catch (e) {
      developer.log('Login error: $e');
      rethrow;
    }
  }

  // Register a new user
  static Future<User> register({
    required String name,
    required String email,
    required String password,
    String? language,
    String? level,
    String? reason,
    int? dailyGoal,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password, // Send plain password (will be hashed by backend)
          if (language != null) 'language': language,
          if (level != null) 'level': level,
          if (reason != null) 'reason': reason,
          if (dailyGoal != null) 'dailyGoal': dailyGoal,
        }),
      );

      final responseData = _handleResponse(response);
      final userData = responseData['user'];
      
      // Filter the API response to match the User model expectations
      // Extract onboarding preferences separately to avoid conflicts
      final filteredUserData = {
        'id': userData['id'],
        'name': userData['name'],
        'xp': userData['xp'] ?? 0,
        'level': (userData['level'] is int) ? userData['level'] : 1, // Ensure it's an int, default to 1
        'streak': userData['streak'] ?? 0,
        'lastActiveDate': userData['created_at'],
        'dailyGoal': (userData['daily_goal'] is int) ? userData['daily_goal'] : ((userData['dailyGoal'] is int) ? userData['dailyGoal'] : 100),
        'dailyXpEarned': userData['dailyXpEarned'] ?? 0,
        'settings': userData['settings'] ?? {},
      };

      // Save auth data
      await _saveAuthData(
        responseData['token'],
        userData, // Store the original user data with all fields
      );

      return User.fromJson(filteredUserData);
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
  static Future<User> getCurrentUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: await _getAuthHeaders(),
      );

      final responseData = _handleResponse(response);
      
      // Filter the API response to match the User model expectations
      final filteredUserData = {
        'id': responseData['id'],
        'name': responseData['name'],
        'xp': responseData['xp'] ?? 0,
        'level': responseData['level'] is int ? responseData['level'] : 1, // Ensure it's an int, default to 1
        'streak': responseData['streak'] ?? 0,
        'lastActiveDate': responseData['created_at'],
        'dailyGoal': (responseData['daily_goal'] is int) ? responseData['daily_goal'] : ((responseData['dailyGoal'] is int) ? responseData['dailyGoal'] : 100),
        'dailyXpEarned': responseData['dailyXpEarned'] ?? 0,
        'settings': responseData['settings'] ?? {},
      };
      
      return User.fromJson(filteredUserData);
    } catch (e) {
      developer.log('Get current user error: $e');
      rethrow;
    }
  }

  // Update user profile
  static Future<User> updateProfile({
    String? name,
    String? language,
    String? level,
    String? reason,
    int? dailyGoal,
    bool? onboardingCompleted,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/users/profile'),
        headers: await _getAuthHeaders(),
        body: jsonEncode({
          if (name != null) 'name': name,
          if (language != null) 'language': language,
          if (level != null) 'level': level,
          if (reason != null) 'reason': reason,
          if (dailyGoal != null) 'dailyGoal': dailyGoal,
          if (onboardingCompleted != null) 'onboarding_completed': onboardingCompleted,
        }),
      );

      final responseData = _handleResponse(response);
      
      // Filter the API response to match the User model expectations
      // Extract onboarding preferences separately to avoid conflicts
      final filteredUserData = {
        'id': responseData['id'],
        'name': responseData['name'],
        'xp': responseData['xp'] ?? 0,
        'level': responseData['level'] is int ? responseData['level'] : 1, // Ensure it's an int, default to 1
        'streak': responseData['streak'] ?? 0,
        'lastActiveDate': responseData['created_at'],
        'dailyGoal': (responseData['daily_goal'] is int) ? responseData['daily_goal'] : ((responseData['dailyGoal'] is int) ? responseData['dailyGoal'] : 100),
        'dailyXpEarned': responseData['dailyXpEarned'] ?? 0,
        'settings': responseData['settings'] ?? {},
      };
      
      await _saveAuthData(
        await getToken() ?? '',
        responseData,
      );

      return User.fromJson(filteredUserData);
    } catch (e) {
      developer.log('Update profile error: $e');
      rethrow;
    }
  }

  // Helper method to handle API responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    final responseData = jsonDecode(response.body);
    
    if (response.statusCode >= 400) {
      throw Exception(responseData['message'] ?? 'An error occurred');
    }

    return responseData;
  }
}