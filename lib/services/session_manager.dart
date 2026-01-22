import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../services/progress_service.dart';

class SessionManager {
  static const _sessionKey = 'lanet_user_session';
  static const _lastActiveKey = 'lanet_last_active';
  static const _completedCategoriesKey = 'lanet_completed_categories';
  
  final ProgressService _progressService = ProgressService();
  
  // Save user's current state
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
    
    await prefs.setString(_sessionKey, json.encode(sessionData));
    await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
  }
  
  // Restore user's last session
  Future<Map<String, dynamic>?> restoreSession() async {
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
  
  // Track completed categories for progress
  Future<void> markCategoryCompleted(String category) async {
    final prefs = await SharedPreferences.getInstance();
    final completed = getCompletedCategories();
    if (!completed.contains(category)) {
      completed.add(category);
      await prefs.setStringList(_completedCategoriesKey, completed);
    }
  }
  
  List<String> getCompletedCategories() {
    // This would typically come from shared preferences
    // For now, we'll implement a simple version
    return [];
  }
  
  // Get personalized recommendations based on progress
  Future<List<String>> getRecommendedCategories() async {
    final completed = getCompletedCategories();
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