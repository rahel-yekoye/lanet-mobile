import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _authToken;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  String? get authToken => _authToken;
  String? get userId => _userData?['id'];
  Map<String, dynamic>? get userData => _userData;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();

      if (token != null && userData != null) {
        _authToken = token;
        _userData = userData;
        _isAuthenticated = true;
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      await _clearAuthState();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final user = await AuthService.login(email, password);
      await _updateAuthState();
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? language,
    String? level,
    String? reason,
  }) async {
    try {
      await AuthService.register(
        name: name,
        email: email,
        password: password,
        language: language,
        level: level,
        reason: reason,
      );
      await _updateAuthState();
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await AuthService.logout();
      await _clearAuthState();
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  Future<void> _updateAuthState() async {
    try {
      final token = await AuthService.getToken();
      final userData = await AuthService.getUserData();

      if (token != null && userData != null) {
        _authToken = token;
        _userData = userData;
        _isAuthenticated = true;
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      debugPrint('Error updating auth state: $e');
      await _clearAuthState();
    }
    notifyListeners();
  }

  Future<void> _clearAuthState() async {
    _authToken = null;
    _userData = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Add this method to update user profile
  Future<bool> updateProfile({
    String? name,
    String? language,
    String? level,
    String? reason,
    int? dailyGoal,
  }) async {
    try {
      await AuthService.updateProfile(
        name: name,
        language: language,
        level: level,
        reason: reason,
        dailyGoal: dailyGoal,
      );
      await _updateAuthState();
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }
}