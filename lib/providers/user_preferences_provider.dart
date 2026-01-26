import 'package:flutter/foundation.dart';
import '../models/user_preferences_model.dart';
import '../services/user_preferences_service.dart';
import '../config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserPreferencesProvider with ChangeNotifier {
  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _error;
  bool _hasChecked = false;

  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasChecked => _hasChecked;
  bool get hasPreferences => _preferences != null;

  /// Check if user has preferences and load them
  Future<void> checkAndLoadPreferences() async {
    if (_hasChecked) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isDemoMode) {
        _hasChecked = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _hasChecked = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final hasPrefs = await UserPreferencesService.hasPreferences(userId);
      if (hasPrefs) {
        _preferences = await UserPreferencesService.getPreferences(userId);
      }

      _hasChecked = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Error checking preferences: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save preferences (called after onboarding completion)
  Future<void> savePreferences({
    required String preferredLanguage,
    required String proficiencyLevel,
    required List<String> learningReasons,
    required int dailyGoalMinutes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isDemoMode) {
        // Create mock preferences for demo
        _preferences = UserPreferences(
          id: 'demo-id',
          userId: 'demo-user',
          preferredLanguage: preferredLanguage,
          proficiencyLevel: proficiencyLevel,
          learningReasons: learningReasons,
          dailyGoalMinutes: dailyGoalMinutes,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      _preferences = await UserPreferencesService.savePreferences(
        userId: userId,
        preferredLanguage: preferredLanguage,
        proficiencyLevel: proficiencyLevel,
        learningReasons: learningReasons,
        dailyGoalMinutes: dailyGoalMinutes,
      );
    } catch (e) {
      _error = e.toString();
      debugPrint('Error saving preferences: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update preferences
  Future<void> updatePreferences({
    String? preferredLanguage,
    String? proficiencyLevel,
    List<String>? learningReasons,
    int? dailyGoalMinutes,
  }) async {
    if (_preferences == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (SupabaseConfig.isDemoMode) {
        _preferences = _preferences!.copyWith(
          preferredLanguage: preferredLanguage,
          proficiencyLevel: proficiencyLevel,
          learningReasons: learningReasons,
          dailyGoalMinutes: dailyGoalMinutes,
          updatedAt: DateTime.now(),
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updated = await UserPreferencesService.updatePreferences(
        userId: userId,
        preferredLanguage: preferredLanguage,
        proficiencyLevel: proficiencyLevel,
        learningReasons: learningReasons,
        dailyGoalMinutes: dailyGoalMinutes,
      );

      if (updated != null) {
        _preferences = updated;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating preferences: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear preferences (for logout)
  void clear() {
    _preferences = null;
    _hasChecked = false;
    _error = null;
    notifyListeners();
  }
}

