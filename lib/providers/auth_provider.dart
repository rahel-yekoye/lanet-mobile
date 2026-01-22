import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  String? _authToken;
  Map<String, dynamic>? _userData;

  // --------------------
  // Getters
  // --------------------

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  String? get authToken => _authToken;
  String? get userId => _userData?['id'];
  Map<String, dynamic>? get userData => _userData;

  /// ✅ single source of truth for onboarding
  bool get onboardingCompleted {
    if (_userData == null) return false;

    // Accept backend variations: snake_case or camelCase
    final snake = _userData?['onboarding_completed'];
    final camel = _userData?['onboardingCompleted'];
    final alt = _userData?['onboardingComplete'];

    return (snake == true) || (camel == true) || (alt == true);
  }

  AuthProvider() {
    checkAuthStatus();
  }

  // --------------------
  // Initial auth check
  // --------------------

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

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

    _isLoading = false;
    notifyListeners();
  }

  // --------------------
  // Login
  // --------------------

  Future<bool> login(String email, String password) async {
    try {
      await AuthService.login(email, password);
      await _updateAuthState();
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    }
  }

  // --------------------
  // Register
  // --------------------

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await AuthService.register(
        name: name,
        email: email,
        password: password,
      );
      await _updateAuthState();
      return _isAuthenticated;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    }
  }

  // --------------------
  // Logout
  // --------------------

  Future<void> logout() async {
    try {
      await AuthService.logout();
      await _clearAuthState();
    } catch (e) {
      debugPrint('Logout error: $e');
      rethrow;
    }
  }

  // --------------------
  // Update auth state
  // --------------------

  Future<void> _updateAuthState() async {
    _isLoading = true;
    notifyListeners();

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

    _isLoading = false;
    notifyListeners();
  }

  // --------------------
  // Clear state
  // --------------------

  Future<void> _clearAuthState() async {
    _authToken = null;
    _userData = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // --------------------
  // ✅ Onboarding completion
  // --------------------
  // NOTE: Only uses fields AuthService already supports

  Future<void> markOnboardingCompleted({
    required String language,
    required String level,
    required String reason,
    required int dailyGoal,
  }) async {
    try {
      await AuthService.updateProfile(
        language: language,
        level: level,
        reason: reason,
        dailyGoal: dailyGoal,
        onboardingCompleted: true,
      );

      await _updateAuthState();
    } catch (e) {
      debugPrint('Onboarding completion error: $e');
      rethrow;
    }
  }

  // --------------------
  // Profile updates (non-onboarding)
  // --------------------

  Future<void> updateProfile({
    String? name,
    String? language,
    String? level,
    String? reason,
    int? dailyGoal,
    bool? onboardingCompleted,
  }) async {
    try {
      await AuthService.updateProfile(
        name: name,
        language: language,
        level: level,
        reason: reason,
        dailyGoal: dailyGoal,
        onboardingCompleted: onboardingCompleted,
      );
      await _updateAuthState();
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    }
  }
}
