import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/progress_service.dart';
import 'progress_sync_service.dart';

class SessionManager {
  static const _sessionKey = 'lanet_user_session';
  static const _lastActiveKey = 'lanet_last_active';
  static const _completedCategoriesKey = 'lanet_completed_categories';
  
  final ProgressService _progressService = ProgressService();
  
  // Save user's current state (both local and Supabase)
  Future<void> saveSession({
    required String currentCategory,
    required String currentScreen,
    Map<String, dynamic>? additionalData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionData = {
      'category': currentCategory,
      'screen': currentScreen,
      'timestamp': DateTime.now().toIso8601String(),
      'additionalData': additionalData ?? {},
    };
    
    // Save locally
    await prefs.setString(_sessionKey, json.encode(sessionData));
    await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
    
    // Also save to Supabase for persistence across devices
    try {
      await ProgressSyncService.saveSession(
        category: currentCategory,
        screen: currentScreen,
        additionalData: additionalData,
      );
    } catch (e) {
      // Don't throw - local storage is sufficient
      print('Error saving session to Supabase: $e');
    }
  }
  
  // Restore user's last session (try Supabase first, then local)
  Future<Map<String, dynamic>?> restoreSession() async {
    // Try Supabase first
    try {
      final supabaseSession = await ProgressSyncService.getSession();
      if (supabaseSession != null) {
        // Also update local storage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sessionKey, json.encode(supabaseSession));
        return supabaseSession;
      }
    } catch (e) {
      print('Error fetching session from Supabase: $e');
    }
    
    // Fallback to local storage
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString(_sessionKey);
    
    if (sessionJson == null) return null;
    
    try {
      return json.decode(sessionJson) as Map<String, dynamic>;
    } catch (e) {
      // Corrupted session data
      await clearSession();
      return null;
    }
  }
  
  // Track completed categories for progress (both local and Supabase)
  Future<void> markCategoryCompleted(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = await getCompletedCategories();
    if (!completed.contains(category)) {
      completed.add(category);
      await prefs.setStringList(_completedCategoriesKey, completed);
      
      // Also save to Supabase
      try {
        await ProgressSyncService.saveCompletedCategory(category);
      } catch (e) {
        print('Error saving completed category to Supabase: $e');
      }
    }
  }
  
  Future<List<String>> getCompletedCategories() async {
    // Try Supabase first (for persistence across logins)
    // Always fetch from Supabase if user is logged in to get latest progress
    try {
      final supabaseCategories = await ProgressSyncService.getCompletedCategories();
      // Update local storage to match Supabase (even if empty, to keep in sync)
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_completedCategoriesKey, supabaseCategories);
      return supabaseCategories;
    } catch (e) {
      print('Error fetching completed categories from Supabase: $e');
      // Fallback to local storage if Supabase fetch fails
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_completedCategoriesKey) ?? <String>[];
    }
  }
  
  // Get personalized recommendations based on progress
  Future<List<String>> getRecommendedCategories() async {
    final completed = await getCompletedCategories();
    // Return categories that haven't been completed yet
    // This is a simplified version - you'd want more sophisticated logic
    return ['basics', 'family', 'food', 'travel']
        .where((cat) => !completed.contains(cat))
        .toList();
  }
  
  // Calculate user's learning level
  Future<String> getUserLevel() async {
    final streak = await _progressService.getStreak();
    final dailyXP = await _progressService.getDailyXP();
    final achievements = await _progressService.getAchievementsCount();
    
    if (streak >= 30 && achievements >= 10) return 'Expert';
    if (streak >= 14 && achievements >= 5) return 'Advanced';
    if (streak >= 7 && achievements >= 2) return 'Intermediate';
    return 'Beginner';
  }
  
  // Clear session data (for logout/reset)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_lastActiveKey);
    await prefs.remove(_completedCategoriesKey);
  }
  
  // Check if session is recent (within 24 hours)
  Future<bool> isRecentSession() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString(_lastActiveKey);
    
    if (lastActiveStr == null) return false;
    
    try {
      final lastActive = DateTime.parse(lastActiveStr);
      final now = DateTime.now();
      final difference = now.difference(lastActive);
      
      return difference.inHours < 24;
    } catch (e) {
      return false;
    }
  }
}

// Helper method to determine where to navigate
Future<String> getSmartRedirectLocation(String currentLocation) async {
  if (currentLocation == '/home' || currentLocation == '/login' || currentLocation == '/register' || currentLocation.startsWith('/onboarding')) {
    return currentLocation; // Don't redirect from these locations
  }
  
  final sessionManager = SessionManager();
  final session = await sessionManager.restoreSession();
  
  if (session != null && await sessionManager.isRecentSession()) {
    final category = session['category'] as String?;
    final screen = session['screen'] as String?;
    
    // Navigate to where user left off
    if (category != null && screen != null) {
      if (screen == 'practice') {
        return '/practice?category=$category';
      } else {
        return '/home';
      }
    } else {
      return '/home';
    }
  } else {
    // Fresh start or old session - go to home
    return '/home';
  }
}
