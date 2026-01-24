import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../models/user_model.dart' as app_model;

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  String? _authToken;
  Map<String, dynamic>? _userData;
  app_model.User? _userModel;

  // --------------------
  // Getters
  // --------------------

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  String? get authToken => _authToken;
  String? get userId => _userData?['id'];
  Map<String, dynamic>? get userData => _userData;
  app_model.User? get userModel => _userModel;

  /// ✅ single source of truth for onboarding
  bool get onboardingCompleted {
    if (_userData == null) return false;

    // Accept backend variations: snake_case or camelCase
    final snake = _userData?['onboarding_completed'];
    final camel = _userData?['onboardingCompleted'];
    final alt = _userData?['onboardingComplete'];
    
    // Check if essential onboarding data exists
    final hasLanguage = _userData?['language'] != null && _userData!['language'].toString().isNotEmpty;
    final hasLevel = _userData?['level'] != null && _userData!['level'].toString().isNotEmpty;
    final hasReason = _userData?['reason'] != null && _userData!['reason'].toString().isNotEmpty;
    final hasDailyGoal = (_userData?['dailyGoal'] != null && _userData!['dailyGoal'] != 0) || 
                        (_userData?['daily_goal'] != null && _userData!['daily_goal'] != 0);
    
    final hasEssentialData = hasLanguage || hasLevel || hasReason || hasDailyGoal;

    return (snake == true) || (camel == true) || (alt == true) || hasEssentialData;
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
      // Check Supabase auth session
      final session = SupabaseService.client.auth.currentSession;
      if (session?.user != null) {
        // User is authenticated with Supabase
        _isAuthenticated = true;
        _authToken = session!.accessToken;
        
        // Fetch user data
        final userData = await SupabaseService.fetchUserData();
        if (userData != null) {
          _userData = userData;
          try {
            _userModel = app_model.User.fromJson(userData);
          } catch (e) {
            debugPrint('Error creating user model: $e');
          }
        } else {
          // Create minimal user data if not found
          _userData = {
            'id': session.user.id,
            'name': session.user.userMetadata?['full_name'] ?? session.user.email?.split('@')[0] ?? '',
            'email': session.user.email ?? '',
            'xp': 0,
            'level': 1,
            'streak': 0,
            'lastActiveDate': DateTime.now().toIso8601String(),
            'dailyGoal': 100,
            'dailyXpEarned': 0,
            'settings': {},
          };
          try {
            _userModel = app_model.User.fromJson(_userData!);
          } catch (e) {
            debugPrint('Error creating user model: $e');
          }
        }
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
      // Check Supabase auth session
      final session = SupabaseService.client.auth.currentSession;
      if (session?.user != null) {
        // User is authenticated with Supabase
        _isAuthenticated = true;
        _authToken = session!.accessToken;
        
        // Fetch user data
        final userData = await SupabaseService.fetchUserData();
        if (userData != null) {
          _userData = userData;
          try {
            _userModel = app_model.User.fromJson(userData);
          } catch (e) {
            debugPrint('Error creating user model: $e');
          }
        } else {
          // Create minimal user data if not found
          _userData = {
            'id': session.user.id,
            'name': session.user.userMetadata?['full_name'] ?? session.user.email?.split('@')[0] ?? '',
            'email': session.user.email ?? '',
            'xp': 0,
            'level': 1,
            'streak': 0,
            'lastActiveDate': DateTime.now().toIso8601String(),
            'dailyGoal': 100,
            'dailyXpEarned': 0,
            'settings': {},
          };
          try {
            _userModel = app_model.User.fromJson(_userData!);
          } catch (e) {
            debugPrint('Error creating user model: $e');
          }
        }
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
