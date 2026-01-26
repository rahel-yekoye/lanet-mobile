import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/progress_service.dart';
import '../services/onboarding_service.dart';
import '../models/user_model.dart' as app_model;
import '../config/supabase_config.dart';

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
  /// Now checks local storage (OnboardingService) instead of requiring authentication
  bool get onboardingCompleted {
    if (_localOnboardingCompleted) return true;
    if (_userData == null) return false;

    // Accept backend variations: snake_case or camelCase
    final snake = _userData?['onboarding_completed'];
    final camel = _userData?['onboardingCompleted'];
    final alt = _userData?['onboardingComplete'];

    // Explicit flags (set at the very end of onboarding) - this is the PRIMARY check
    if (snake == true || camel == true || alt == true) return true;

    // Legacy users with XP are considered done
    final hasXP = (_userData?['xp'] is num) && (_userData!['xp'] as num) > 0;
    if (hasXP) return true;

    // CRITICAL: Only consider onboarding complete if ALL four fields are present
    // This prevents premature completion when user is still in the flow
    final hasLanguage = _userData?['language'] != null &&
        _userData!['language'].toString().isNotEmpty;
    final hasLevel = _userData?['level'] != null &&
        _userData!['level'].toString().isNotEmpty;
    final hasReason = _userData?['reason'] != null &&
        _userData!['reason'].toString().isNotEmpty;
    final hasDailyGoal = (_userData?['daily_goal'] != null) ||
        (_userData?['dailyGoal'] != null);
    
    // Require ALL four fields to be present, not just three
    if (hasLanguage && hasLevel && hasReason && hasDailyGoal) return true;

    return false;
  }

  // Add a local override for immediate feedback
  bool _localOnboardingCompleted = false;

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
      debugPrint(
          'AuthProvider.checkAuthStatus: Checking authentication status');
      if (SupabaseConfig.isDemoMode) {
        final stored = await AuthService.getUserData();
        if (stored != null) {
          _isAuthenticated = true;
          _authToken = null;
          _userData = stored;
          try {
            _userModel = app_model.User.fromJson(stored);
          } catch (_) {}
        } else {
          await _clearAuthState();
        }
      } else {
        final session = SupabaseService.client.auth.currentSession;
        if (session?.user != null) {
          debugPrint(
              'AuthProvider.checkAuthStatus: User is authenticated, fetching user data');

          _isAuthenticated = true;
          _authToken = session!.accessToken;

          final userData = await SupabaseService.fetchUserData();
          if (userData != null) {
            _userData = userData;
            try {
              _userModel = app_model.User.fromJson(userData);
            } catch (e) {
              debugPrint('Error creating user model: $e');
            }
            try {
              final ps = ProgressService();
              final sDaily =
                  userData['daily_xp_earned'] ?? userData['dailyXpEarned'];
              final sStreak = userData['streak'];
              final sGoal = userData['daily_goal'] ?? userData['dailyGoal'];
              if (sGoal != null) {
                final g = sGoal is num
                    ? sGoal.toInt()
                    : int.tryParse(sGoal.toString());
                if (g != null) await ps.setDailyGoal(g);
              }
              if (sDaily != null) {
                final dxp = sDaily is num
                    ? sDaily.toInt()
                    : int.tryParse(sDaily.toString());
                if (dxp != null) await ps.setDailyXPForToday(dxp);
              }
              if (sStreak != null) {
                final st = sStreak is num
                    ? sStreak.toInt()
                    : int.tryParse(sStreak.toString());
                if (st != null) await ps.setStreak(st);
              }
            } catch (_) {}
          } else {
            _userData = {
              'id': session.user.id,
              'name': session.user.userMetadata?['full_name'] ??
                  session.user.email?.split('@')[0] ??
                  '',
              'email': session.user.email ?? '',
              'xp': 0,
              'level': 1,
              'streak': 0,
              'lastActiveDate': DateTime.now().toIso8601String(),
              'dailyGoal': 5,
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
          debugPrint(
              'AuthProvider.checkAuthStatus: No authenticated session, clearing auth state');
          await _clearAuthState();
        }
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      debugPrint('Error type: ${e.runtimeType}');

      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('socket') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('ssl') ||
          errorMsg.contains('certificate')) {
        debugPrint(
            'Network-related error in auth status check, keeping current state');
      } else {
        await _clearAuthState();
      }
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
    String? role,
  }) async {
    try {
      await AuthService.register(
        name: name,
        email: email,
        password: password,
        role: role,
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
      // Even if logout fails, clear the local auth state
      await _clearAuthState();
      rethrow;
    }
  }

  // --------------------
  // Update auth state
  // --------------------

  /// Refresh user data from Supabase
  Future<void> refreshUserData() async {
    await _updateAuthState();
  }

  Future<void> _updateAuthState() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint(
          'AuthProvider._updateAuthState: Updating authentication state');
      if (SupabaseConfig.isDemoMode) {
        final stored = await AuthService.getUserData();
        if (stored != null) {
          _isAuthenticated = true;
          _authToken = null;
          _userData = stored;
          try {
            _userModel = app_model.User.fromJson(stored);
          } catch (_) {}
        } else {
          await _clearAuthState();
        }
      } else {
        final session = SupabaseService.client.auth.currentSession;
        if (session?.user != null) {
          debugPrint(
              'AuthProvider._updateAuthState: User is authenticated, fetching user data');

          // User is authenticated with Supabase
          _isAuthenticated = true;
          _authToken = session!.accessToken;

          // Wait a moment to ensure session is fully established
          await Future.delayed(const Duration(milliseconds: 300));

          // Fetch user data with retry logic
          Map<String, dynamic>? userData;
          int retries = 3;
          while (userData == null && retries > 0) {
            userData = await SupabaseService.fetchUserData();
            if (userData == null && retries > 1) {
              debugPrint('AuthProvider._updateAuthState: User data not found, retrying... ($retries attempts left)');
              await Future.delayed(const Duration(milliseconds: 300));
            }
            retries--;
          }
          
          debugPrint('AuthProvider._updateAuthState: Fetched user data: ${userData != null ? "Success" : "Failed"}');
          if (userData != null) {
            _userData = userData;
            try {
              _userModel = app_model.User.fromJson(userData);
            } catch (e) {
              debugPrint('Error creating user model: $e');
            }
            try {
              final ps = ProgressService();
              // Sync daily XP
              final sDaily =
                  userData['daily_xp_earned'] ?? userData['dailyXpEarned'];
              if (sDaily != null) {
                final dxp = sDaily is num
                    ? sDaily.toInt()
                    : int.tryParse(sDaily.toString());
                if (dxp != null) await ps.setDailyXPForToday(dxp);
              }
              // Sync streak
              final sStreak = userData['streak'];
              if (sStreak != null) {
                final st = sStreak is num
                    ? sStreak.toInt()
                    : int.tryParse(sStreak.toString());
                if (st != null) await ps.setStreak(st);
              }
              // Sync daily goal
              final sGoal = userData['daily_goal'] ?? userData['dailyGoal'];
              if (sGoal != null) {
                final g = sGoal is num
                    ? sGoal.toInt()
                    : int.tryParse(sGoal.toString());
                if (g != null && g > 0) await ps.setDailyGoal(g);
              }
              debugPrint('DEBUG: Synced progress from Supabase - XP: ${userData['xp']}, Streak: $sStreak, Daily XP: $sDaily, Goal: $sGoal');
            } catch (e) {
              debugPrint('Error syncing progress: $e');
            }
          } else {
            // Create minimal user data if not found
            _userData = {
              'id': session.user.id,
              'name': session.user.userMetadata?['full_name'] ??
                  session.user.email?.split('@')[0] ??
                  '',
              'email': session.user.email ?? '',
              'xp': 0,
              'level': 1,
              'streak': 0,
              'lastActiveDate': DateTime.now().toIso8601String(),
              'dailyGoal': 5,
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
          debugPrint(
              'AuthProvider._updateAuthState: No authenticated session, clearing auth state');
          await _clearAuthState();
        }
      }
    } catch (e) {
      debugPrint('Error updating auth state: $e');
      debugPrint('Error type: ${e.runtimeType}');

      // Check if it's a network error
      final errorMsg = e.toString().toLowerCase();
      if (errorMsg.contains('network') ||
          errorMsg.contains('fetch') ||
          errorMsg.contains('timeout') ||
          errorMsg.contains('socket') ||
          errorMsg.contains('connection') ||
          errorMsg.contains('ssl') ||
          errorMsg.contains('certificate')) {
        debugPrint(
            'Network-related error in update auth state, keeping current state');
        // For network errors, we might want to keep the current state instead of clearing it
        // This allows offline usage if user was previously logged in
      } else {
        await _clearAuthState();
      }
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
      // Optimistically update local state to prevent routing loops
      _localOnboardingCompleted = true;
      // Also set essential fields locally
      final updated = Map<String, dynamic>.from(_userData ?? {});
      updated['language'] = language;
      updated['level'] = level;
      updated['reason'] = reason;
      updated['daily_goal'] = dailyGoal;
      updated['dailyGoal'] = dailyGoal;
      updated['onboarding_completed'] = true;
      updated['onboardingCompleted'] = true;
      _userData = updated;
      notifyListeners();

      // Save to local storage (no authentication required)
      await OnboardingService.saveSelections(
        language: language,
        level: level,
        reason: reason,
        goal: dailyGoal.toString(),
      );
      await OnboardingService.completeOnboarding();

      // CRITICAL: Save to database via AuthService
      // This ensures the preferences are persisted to Supabase
      if (_isAuthenticated) {
        try {
          await AuthService.updateProfile(
            language: language,
            level: level,
            reason: reason,
            dailyGoal: dailyGoal,
            onboardingCompleted: true,
          );
          debugPrint('Onboarding preferences saved to database successfully');
        } catch (e) {
          debugPrint('Error saving onboarding preferences to database: $e');
          // Continue even if database save fails - local state is already updated
        }
      }

      // Update user data with onboarding info
      if (_userData != null) {
        _userData!['language'] = language;
        _userData!['level'] = level;
        _userData!['reason'] = reason;
        _userData!['onboarding_completed'] = true;
        _userData!['dailyGoal'] = dailyGoal;
        _userData!['daily_goal'] = dailyGoal;
      }

      // 3. Silent Sync: Fetch fresh data without triggering global isLoading
      // This ensures we have the server's truth without flashing loading screens
      final freshData = await SupabaseService.fetchUserData();
      if (freshData != null) {
        // CRITICAL: Preserve local optimistic updates if server data is lagging/missing
        // This prevents routing loops where the router sees the data disappear
        // We check _userData because it contains the optimistic updates we just applied
        if (_userData != null) {
          if (freshData['language'] == null ||
              freshData['language'].toString().isEmpty) {
            freshData['language'] = _userData!['language'];
          }
          if (freshData['level'] == null ||
              freshData['level'].toString().isEmpty) {
            freshData['level'] = _userData!['level'];
          }
          if (freshData['reason'] == null ||
              freshData['reason'].toString().isEmpty) {
            freshData['reason'] = _userData!['reason'];
          }
          if (freshData['dailyGoal'] == null) {
            freshData['dailyGoal'] = _userData!['dailyGoal'];
            freshData['daily_goal'] = _userData!['daily_goal'];
          }
          if (freshData['onboardingCompleted'] != true &&
              _userData!['onboardingCompleted'] == true) {
            freshData['onboardingCompleted'] = true;
            freshData['onboarding_completed'] = true;
          }
        }

        _userData = freshData;
        try {
          _userModel = app_model.User.fromJson(freshData);
        } catch (e) {
          debugPrint('Error creating user model during silent sync: $e');
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Onboarding completion error: $e');
      // Keep local completion to avoid redirect loop; backend sync can happen later
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
    // Optimistic update: Update local state immediately to prevent routing loops
    // This allows the Router to see the new state (e.g. language set) before the server confirms it
    final newUserData = Map<String, dynamic>.from(_userData ?? {});
    if (name != null) newUserData['name'] = name;
    if (language != null) newUserData['language'] = language;
    if (level != null) newUserData['level'] = level;
    if (reason != null) newUserData['reason'] = reason;
    if (dailyGoal != null) {
      newUserData['daily_goal'] = dailyGoal;
      newUserData['dailyGoal'] = dailyGoal;
    }
    if (onboardingCompleted != null) {
      newUserData['onboarding_completed'] = onboardingCompleted;
      newUserData['onboardingCompleted'] = onboardingCompleted;
    }

    _userData = newUserData;
    // CRITICAL: Don't notify listeners during intermediate onboarding steps
    // This prevents the router from re-evaluating and redirecting away from onboarding screens
    // Only notify if onboarding is being completed (final step) or if it's a non-onboarding update
    final isOnboardingStep = language != null || level != null || reason != null || dailyGoal != null;
    if (onboardingCompleted == true || !isOnboardingStep) {
      notifyListeners();
    }

    try {
      // Save to Supabase in the background
      await AuthService.updateProfile(
        name: name,
        language: language,
        level: level,
        reason: reason,
        dailyGoal: dailyGoal,
        onboardingCompleted: onboardingCompleted,
      );
      
      // CRITICAL: Only update auth state if onboarding is being completed
      // For intermediate onboarding steps (language, level, reason, dailyGoal),
      // we do NOT call _updateAuthState() because it triggers router re-evaluation
      // which causes premature redirects away from onboarding screens
      if (onboardingCompleted == true) {
        // Final step - update auth state to get canonical data and notify
        await _updateAuthState();
        notifyListeners();
      }
      // For intermediate steps, we just save to Supabase silently
      // The optimistic update to _userData is enough for the router to see the progress
      // and allow navigation to the next onboarding screen
    } catch (e) {
      debugPrint('Update profile error: $e');
      // We do NOT revert optimistic updates for onboarding steps (language, etc.)
      // because getting stuck in a loop is worse than having a temporary sync mismatch.
      // The silent sync in future app starts will correct it.

      // However, we should rethrow if it's a critical error that UI needs to handle
      // But for onboarding flow, we prefer to proceed.
      print(
          'DEBUG: Suppressing error in updateProfile to allow navigation: $e');
    }
  }
}
