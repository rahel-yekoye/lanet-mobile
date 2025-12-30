import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String keyLanguage = 'onboarding_language';
  static const String keyLevel = 'onboarding_level';
  static const String keyReason = 'onboarding_reason';
  static const String keyGoal = 'onboarding_goal';
  static const String keyCompleted = 'onboarding_completed';

  // Save a value
  static Future<void> setValue(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
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
}
