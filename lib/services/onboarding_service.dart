// lib/services/onboarding_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String keyLanguage = 'onboarding_language';
  static const String keyLevel = 'onboarding_level';
  static const String keyReason = 'onboarding_reason';
  static const String keyGoal = 'onboarding_goal';
  static const String keyCompleted = 'onboarding_completed';
  static const String keyName = 'user_name';
  static const String keyEmail = 'user_email';

  // Save a value
  static Future<void> setValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // Get a value
  static Future<String?> getValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  // Save user selections
  static Future<void> saveSelections({
    String? language,
    String? level,
    String? reason,
    String? goal,
    String? name,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (language != null) await prefs.setString(keyLanguage, language);
    if (level != null) await prefs.setString(keyLevel, level);
    if (reason != null) await prefs.setString(keyReason, reason);
    if (goal != null) await prefs.setString(keyGoal, goal);
    if (name != null) await prefs.setString(keyName, name);
    if (email != null) await prefs.setString(keyEmail, email);
  }

  // Get all user selections
  static Future<Map<String, String>> getSelections() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'language': prefs.getString(keyLanguage) ?? '',
      'level': prefs.getString(keyLevel) ?? '',
      'reason': prefs.getString(keyReason) ?? '',
      'goal': prefs.getString(keyGoal) ?? '',
      'name': prefs.getString(keyName) ?? '',
      'email': prefs.getString(keyEmail) ?? '',
    };
  }

  // Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyCompleted, true);
  }

  // Check if onboarding is done
  static Future<bool> isCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyCompleted) ?? false;
  }

  // Reset onboarding
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyCompleted);
    await prefs.remove(keyLanguage);
    await prefs.remove(keyLevel);
    await prefs.remove(keyReason);
    await prefs.remove(keyGoal);
    await prefs.remove(keyName);
    await prefs.remove(keyEmail);
  }
}