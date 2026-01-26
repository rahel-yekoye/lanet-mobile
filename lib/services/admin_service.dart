import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer' as developer;
import '../config/supabase_config.dart';
import '../models/admin_models.dart';

/// Service for admin operations
class AdminService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Check if current user is admin
  static Future<bool> isAdmin() async {
    if (SupabaseConfig.isDemoMode) return false;

    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      final role = response?['role'] as String?;
      return role == 'admin';
    } catch (e) {
      // Log error but don't throw - return false to allow normal flow
      print('Error checking admin status: $e');
      return false;
    }
  }

  /// Get user role
  static Future<String?> getUserRole(String userId) async {
    if (SupabaseConfig.isDemoMode) return 'user';

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      return response?['role'] as String? ?? 'user';
    } catch (e) {
      return 'user';
    }
  }

  // ============================================
  // USER MANAGEMENT
  // ============================================

  /// Get paginated list of users (all users including students and admins)
  static Future<List<Map<String, dynamic>>> getUsers({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    if (SupabaseConfig.isDemoMode) {
      return [];
    }

    try {
      // Query from profiles table (which should have all users via trigger)
      // If user_stats view exists and is accessible, it will include all auth.users
      List<Map<String, dynamic>> response = [];
      
      // Try user_stats view first (includes ALL users from auth.users via LEFT JOIN)
      // This is the most reliable source since it includes users even if they don't have profiles
      try {
        var query = _client.from('user_stats').select();
        
        if (searchQuery != null && searchQuery.isNotEmpty) {
          // Search by email - use ilike for case-insensitive search
          final escapedQuery = searchQuery.replaceAll('%', '\\%').replaceAll('_', '\\_');
          final searchPattern = '%$escapedQuery%';
          query = query.ilike('email', searchPattern);
          developer.log('Searching user_stats for email: "$searchQuery" with pattern: "$searchPattern"');
        }

        final userStatsResponse = await query
            .order('joined_at', ascending: false)
            .range((page - 1) * pageSize, page * pageSize - 1);
            
        response = (userStatsResponse as List).map((u) => u as Map<String, dynamic>).toList();
        developer.log('Fetched ${response.length} users from user_stats');
      } catch (e) {
        developer.log('Error fetching from user_stats: $e');
        // Fallback to profiles table if user_stats view fails
        try {
          var query = _client.from('profiles').select('id, full_name, email, role, created_at, blocked');

          if (searchQuery != null && searchQuery.isNotEmpty) {
            final escapedQuery = searchQuery.replaceAll('%', '\\%').replaceAll('_', '\\_');
            final searchPattern = '%$escapedQuery%';
            query = query.ilike('email', searchPattern);
            developer.log('Fallback: Searching profiles for email: "$searchQuery"');
          }

          final profilesResponse = await query
              .order('created_at', ascending: false)
              .range((page - 1) * pageSize, page * pageSize - 1);

          // Convert profiles to user_stats format
          response = (profilesResponse as List).map((p) {
            return {
              'id': p['id'],
              'email': p['email'] ?? '',
              'name': p['full_name'] ?? '',
              'role': p['role'] ?? 'student',
              'blocked': p['blocked'] ?? false,
              'joined_at': p['created_at'],
            } as Map<String, dynamic>;
          }).toList();
          
          developer.log('Fetched ${response.length} users from profiles (fallback)');
        } catch (e2) {
          developer.log('Error fetching from profiles: $e2');
          throw Exception('Failed to fetch users: $e2');
        }
      }
      
      // If still no results and we're searching, try a broader search without pagination
      if (response.isEmpty && searchQuery != null && searchQuery.isNotEmpty) {
        developer.log('No results from paginated query, trying full search without pagination');
        try {
          // Try searching all records without pagination
          var fullQuery = _client.from('profiles').select('id, full_name, email, role, created_at, blocked');
          
          final escapedQuery = searchQuery.replaceAll('%', '\\%').replaceAll('_', '\\_');
          final searchPattern = '%$escapedQuery%';
          // Use email search directly
          fullQuery = fullQuery.ilike('email', searchPattern);
          
          final allProfiles = await fullQuery.order('created_at', ascending: false);
          
          if ((allProfiles as List).isNotEmpty) {
            // Apply pagination manually
            final allList = (allProfiles as List).map((p) {
              return {
                'id': p['id'],
                'email': p['email'] ?? '',
                'name': p['full_name'] ?? '',
                'role': p['role'] ?? 'student',
                'blocked': p['blocked'] ?? false,
                'joined_at': p['created_at'],
              } as Map<String, dynamic>;
            }).toList();
            
            final startIndex = (page - 1) * pageSize;
            final endIndex = startIndex + pageSize;
            response = allList.sublist(
              startIndex < allList.length ? startIndex : allList.length,
              endIndex < allList.length ? endIndex : allList.length,
            );
            developer.log('Found ${response.length} users with full search (from ${allList.length} total)');
          }
        } catch (e3) {
          developer.log('Full search also failed: $e3');
        }
      }

      return response;
    } catch (e) {
      // Provide more detailed error message
      final errorMsg = e.toString();
      if (errorMsg.contains('ERR_NAME_NOT_RESOLVED') || 
          errorMsg.contains('Failed host lookup') ||
          errorMsg.contains('Network')) {
        throw Exception('Network error: Cannot connect to Supabase. Please check your internet connection and Supabase configuration.');
      }
      developer.log('Error fetching users: $e');
      throw Exception('Failed to fetch users: $e');
    }
  }

  /// Block/unblock a user
  static Future<bool> toggleUserBlock(String userId, bool blocked) async {
    if (SupabaseConfig.isDemoMode) return true;

    try {
      await _client
          .from('profiles')
          .update({'blocked': blocked})
          .eq('id', userId);
      return true;
    } catch (e) {
      throw Exception('Failed to update user block status: $e');
    }
  }

  /// Get all completed lessons for a specific user
  static Future<List<Map<String, dynamic>>> getUserCompletedLessons(String userId) async {
    if (SupabaseConfig.isDemoMode) {
      return [];
    }

    try {
      // First get the progress records
      final progressResponse = await _client
          .from('user_lesson_progress')
          .select()
          .eq('user_id', userId)
          .eq('completed', true)
          .order('completed_at', ascending: false);

      final progressList = progressResponse as List;
      if (progressList.isEmpty) return [];

      // Get lesson IDs
      final lessonIds = progressList
          .map((p) => (p as Map<String, dynamic>)['lesson_id'] as String)
          .toList();

      if (lessonIds.isEmpty) return [];

      // Fetch lessons - for compatibility, fetch all and filter in Dart
      // This is more reliable across different Supabase versions
      final allLessonsResponse = await _client
          .from('lessons')
          .select();
      
      final allLessons = allLessonsResponse as List;
      final lessonsResponse = allLessons.where((lesson) {
        final lessonId = (lesson as Map<String, dynamic>)['id'] as String;
        return lessonIds.contains(lessonId);
      }).toList();

      final lessonsMap = <String, Map<String, dynamic>>{};
      for (final lesson in lessonsResponse) {
        final l = lesson as Map<String, dynamic>;
        lessonsMap[l['id'] as String] = l;
      }

      // Combine progress and lesson data
      return progressList.map((progress) {
        final p = progress as Map<String, dynamic>;
        final lessonId = p['lesson_id'] as String;
        final lesson = lessonsMap[lessonId];
        
        return {
          'lesson_id': lessonId,
          'title': lesson?['title'] ?? 'Unknown',
          'category': lesson?['category'] ?? 'Uncategorized',
          'language': lesson?['language'] ?? 'Unknown',
          'score': p['score'] ?? 0,
          'time_spent_seconds': p['time_spent_seconds'] ?? 0,
          'completed_at': p['completed_at'],
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch user lessons: $e');
    }
  }

  /// Get all categories
  static Future<List<Map<String, dynamic>>> getCategories() async {
    if (SupabaseConfig.isDemoMode) {
      return [];
    }

    try {
      final response = await _client
          .from('categories')
          .select()
          .order('order_index');

      return (response as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Create a new category
  static Future<Map<String, dynamic>> createCategory({
    required String name,
    String? description,
    String? icon,
    String? color,
    int? orderIndex,
  }) async {
    if (SupabaseConfig.isDemoMode) {
      throw Exception('Demo mode: Cannot create category');
    }

    try {
      final response = await _client
          .from('categories')
          .insert({
            'name': name,
            'description': description,
            'icon': icon,
            'color': color,
            'order_index': orderIndex ?? 0,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update a category
  static Future<Map<String, dynamic>> updateCategory(
    String categoryId,
    Map<String, dynamic> data,
  ) async {
    if (SupabaseConfig.isDemoMode) {
      throw Exception('Demo mode: Cannot update category');
    }

    try {
      final response = await _client
          .from('categories')
          .update(data)
          .eq('id', categoryId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category
  static Future<void> deleteCategory(String categoryId) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      await _client.from('categories').delete().eq('id', categoryId);
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  // ============================================
  // LESSON MANAGEMENT
  // ============================================

  /// Get paginated list of lessons
  static Future<Map<String, dynamic>> getLessons({
    int page = 1,
    int pageSize = 20,
    String? status,
    String? language,
    String? searchQuery,
  }) async {
    if (SupabaseConfig.isDemoMode) {
      return {
        'lessons': [],
        'total': 0,
        'page': page,
        'pageSize': pageSize,
      };
    }

    try {
      var query = _client.from('lessons').select();

      if (status != null) {
        query = query.eq('status', status);
      }
      if (language != null) {
        query = query.eq('language', language);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      // Get total count first (create a separate query for count)
      var countQuery = _client.from('lessons').select();
      if (status != null) {
        countQuery = countQuery.eq('status', status);
      }
      if (language != null) {
        countQuery = countQuery.eq('language', language);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        countQuery = countQuery.ilike('title', '%$searchQuery%');
      }
      final countList = await countQuery;
      final total = (countList as List).length;

      // Get paginated data
      final response = await query
          .order('created_at', ascending: false)
          .range((page - 1) * pageSize, page * pageSize - 1);

      final lessons = (response as List)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList();

      return {
        'lessons': lessons,
        'total': total,
        'page': page,
        'pageSize': pageSize,
      };
    } catch (e) {
      throw Exception('Failed to fetch lessons: $e');
    }
  }

  /// Get a single lesson with exercises
  static Future<Lesson> getLesson(String lessonId) async {
    if (SupabaseConfig.isDemoMode) {
      throw Exception('Demo mode: Cannot fetch lesson');
    }

    try {
      final lessonResponse = await _client
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .single();

      final exercisesResponse = await _client
          .from('exercises')
          .select()
          .eq('lesson_id', lessonId)
          .order('order_index');

      final lesson = Lesson.fromJson(lessonResponse);
      final exercises = (exercisesResponse as List)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList();

      return lesson.copyWith(exercises: exercises);
    } catch (e) {
      throw Exception('Failed to fetch lesson: $e');
    }
  }

  /// Create a new lesson
  static Future<Lesson> createLesson(Map<String, dynamic> data) async {
    if (SupabaseConfig.isDemoMode) {
      throw Exception('Demo mode: Cannot create lesson');
    }

    try {
      final userId = _client.auth.currentUser?.id;
      final response = await _client
          .from('lessons')
          .insert({
            ...data,
            'created_by': userId,
          })
          .select()
          .single();

      return Lesson.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create lesson: $e');
    }
  }

  /// Update a lesson
  static Future<Lesson> updateLesson(String lessonId, Map<String, dynamic> data) async {
    if (SupabaseConfig.isDemoMode) {
      throw Exception('Demo mode: Cannot update lesson');
    }

    try {
      final response = await _client
          .from('lessons')
          .update(data)
          .eq('id', lessonId)
          .select()
          .single();

      return Lesson.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update lesson: $e');
    }
  }

  /// Delete a lesson
  static Future<void> deleteLesson(String lessonId) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      await _client.from('lessons').delete().eq('id', lessonId);
    } catch (e) {
      throw Exception('Failed to delete lesson: $e');
    }
  }

  /// Create/update an exercise
  static Future<Exercise> saveExercise(Map<String, dynamic> data) async {
    if (SupabaseConfig.isDemoMode) {
      throw Exception('Demo mode: Cannot save exercise');
    }

    try {
      final exerciseId = data['id'] as String?;
      
      if (exerciseId != null && exerciseId != 'new') {
        // Update existing - remove id from update data
        final updateData = Map<String, dynamic>.from(data);
        updateData.remove('id');
        final response = await _client
            .from('exercises')
            .update(updateData)
            .eq('id', exerciseId)
            .select()
            .single();
        return Exercise.fromJson(response);
      } else {
        // Create new - remove id from insert data (let database generate it)
        final insertData = Map<String, dynamic>.from(data);
        insertData.remove('id');
        final response = await _client
            .from('exercises')
            .insert(insertData)
            .select()
            .single();
        return Exercise.fromJson(response);
      }
    } catch (e) {
      throw Exception('Failed to save exercise: $e');
    }
  }

  /// Delete an exercise
  static Future<void> deleteExercise(String exerciseId) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      await _client.from('exercises').delete().eq('id', exerciseId);
    } catch (e) {
      throw Exception('Failed to delete exercise: $e');
    }
  }

  // ============================================
  // ANALYTICS
  // ============================================

  /// Get analytics data using user_preferences and user tables
  static Future<Map<String, dynamic>> getAnalytics() async {
    if (SupabaseConfig.isDemoMode) {
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalLessonsCompleted': 0,
        'topLessons': [],
        'topCategories': [],
        'usersByLanguage': {},
        'usersByLevel': {},
        'usersByReason': {},
        'onboardingCompletionRate': 0.0,
      };
    }

    try {
      // Total users - use user_stats view which includes ALL users from auth.users
      int totalUsers = 0;
      try {
        // Use user_stats view which joins auth.users with profiles
        // Select all columns to ensure the view query works properly
        final totalUsersList = await _client
            .from('user_stats')
            .select();
        totalUsers = (totalUsersList as List).length;
        developer.log('Analytics: Total users from user_stats: $totalUsers');
      } catch (e) {
        developer.log('Error fetching from user_stats: $e');
        // Fallback to profiles table if user_stats view doesn't exist or has issues
        try {
          final totalUsersList = await _client
              .from('profiles')
              .select('id');
          totalUsers = (totalUsersList as List).length;
          developer.log('Analytics: Total users from profiles: $totalUsers');
        } catch (e2) {
          developer.log('Error fetching from profiles: $e2');
          // Last resort: try users table
          try {
            final usersTableList = await _client
                .from('users')
                .select('id');
            totalUsers = (usersTableList as List).length;
            developer.log('Analytics: Total users from users table: $totalUsers');
          } catch (e3) {
            developer.log('Error fetching from users table: $e3');
            // Don't throw, just log and continue with 0
            developer.log('Warning: Could not fetch user count from any source, using 0');
          }
        }
      }

      // Active users (last 7 days) - users who completed lessons
      int activeUsers = 0;
      try {
        final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
        final activeUsersList = await _client
            .from('user_lesson_progress')
            .select('user_id')
            .gte('updated_at', sevenDaysAgo.toIso8601String());
        activeUsers = (activeUsersList as List).map((e) => (e as Map<String, dynamic>)['user_id']).toSet().length;
        developer.log('Analytics: Active users (7d): $activeUsers');
      } catch (e) {
        developer.log('Error fetching active users: $e');
      }

      // Total lessons completed
      int totalLessonsCompleted = 0;
      try {
        // Try to fetch all completed lesson progress records
        final completedList = await _client
            .from('user_lesson_progress')
            .select('id, lesson_id, user_id, completed')
            .eq('completed', true);
        
        totalLessonsCompleted = (completedList as List).length;
        developer.log('Analytics: Total lessons completed: $totalLessonsCompleted');
        developer.log('Analytics: Sample completed records: ${completedList.take(3).toList()}');
        
        // If no results with completed=true, try without filter to see if table has data
        if (totalLessonsCompleted == 0) {
          try {
            final allRecords = await _client
                .from('user_lesson_progress')
                .select('id, completed')
                .limit(10);
            developer.log('Analytics: Sample user_lesson_progress records (first 10): $allRecords');
            if ((allRecords as List).isNotEmpty) {
              // Check if completed field exists and what values it has
              final sample = (allRecords as List).first as Map<String, dynamic>;
              developer.log('Analytics: Sample record structure: $sample');
            }
          } catch (e2) {
            developer.log('Analytics: Error checking user_lesson_progress table structure: $e2');
          }
        }
      } catch (e) {
        developer.log('Error fetching completed lessons: $e');
        developer.log('Error type: ${e.runtimeType}');
        // Try alternative query without completed filter
        try {
          final allProgress = await _client
              .from('user_lesson_progress')
              .select('id');
          developer.log('Analytics: Total user_lesson_progress records (all): ${(allProgress as List).length}');
        } catch (e2) {
          developer.log('Analytics: Alternative query also failed: $e2');
        }
      }

      // Get user preferences data for analytics
      final usersByLanguage = <String, int>{};
      final usersByLevel = <String, int>{};
      final usersByReason = <String, int>{};
      int usersWithOnboarding = 0;
      
      try {
        // Fetch all user preferences - the table has preferred_language, proficiency_level, learning_reasons
        final preferencesList = await _client
            .from('user_preferences')
            .select('preferred_language, proficiency_level, learning_reasons');
        
        developer.log('Analytics: User preferences found: ${preferencesList.length}');
        
        // Analyze preferences
        for (final pref in preferencesList) {
          final p = pref as Map<String, dynamic>;
          
          // Count by language
          final language = p['preferred_language'] as String?;
          if (language != null && language.isNotEmpty) {
            usersByLanguage[language] = (usersByLanguage[language] ?? 0) + 1;
          }
          
          // Count by proficiency level
          final level = p['proficiency_level'] as String?;
          if (level != null && level.isNotEmpty) {
            usersByLevel[level] = (usersByLevel[level] ?? 0) + 1;
          }
          
          // Count by learning reasons (array field)
          final reasons = p['learning_reasons'] as List?;
          if (reasons != null && reasons.isNotEmpty) {
            for (final reason in reasons) {
              final reasonStr = reason.toString();
              usersByReason[reasonStr] = (usersByReason[reasonStr] ?? 0) + 1;
            }
          }
          
          // If user has preferences, they completed onboarding
          if (language != null || level != null) {
            usersWithOnboarding++;
          }
        }
        developer.log('Analytics: Users by language: $usersByLanguage');
        developer.log('Analytics: Users by level: $usersByLevel');
        developer.log('Analytics: Users by reason: $usersByReason');
        developer.log('Analytics: Users with onboarding completed: $usersWithOnboarding');
      } catch (e) {
        developer.log('Error fetching user preferences: $e');
        // Try alternative query if the columns don't exist
        try {
          final allPrefs = await _client.from('user_preferences').select();
          developer.log('Analytics: Found ${allPrefs.length} preference records (alternative query)');
          if ((allPrefs as List).isNotEmpty) {
            final sample = (allPrefs as List).first as Map<String, dynamic>;
            developer.log('Analytics: Sample preference structure: $sample');
          }
        } catch (e2) {
          developer.log('Analytics: Alternative preference query also failed: $e2');
        }
      }

      // Calculate onboarding completion rate
      // Users with preferences have completed onboarding
      final onboardingCompletionRate = totalUsers > 0 
          ? (usersWithOnboarding / totalUsers).clamp(0.0, 1.0)
          : 0.0;

      // Top lessons
      List<Map<String, dynamic>> topLessons = [];
      try {
        final topLessonsResponse = await _client
            .from('lesson_popularity')
            .select()
            .order('completions', ascending: false)
            .limit(5);
        topLessons = (topLessonsResponse as List).cast<Map<String, dynamic>>();
        developer.log('Analytics: Top lessons found: ${topLessons.length}');
      } catch (e) {
        developer.log('Error fetching top lessons: $e');
      }

      // Get category statistics - try user_category_progress if it exists, otherwise skip
      final categoryCompletions = <String, int>{};
      try {
        final categoryProgress = await _client
            .from('user_category_progress')
            .select('category_id, completed')
            .eq('completed', true);
        
        for (final cp in categoryProgress) {
          final c = cp as Map<String, dynamic>;
          final catId = c['category_id'] as String? ?? '';
          if (catId.isNotEmpty) {
            categoryCompletions[catId] = (categoryCompletions[catId] ?? 0) + 1;
          }
        }
        developer.log('Analytics: Category completions: $categoryCompletions');
      } catch (e) {
        // Table might not exist, that's okay - just log and continue
        developer.log('Category progress table not available or error: $e');
      }

      developer.log('Analytics: Final summary - Total Users: $totalUsers, Lessons Completed: $totalLessonsCompleted, Active Users: $activeUsers');
      
      final result = {
        'totalUsers': totalUsers,
        'activeUsers': activeUsers,
        'totalLessonsCompleted': totalLessonsCompleted,
        'topLessons': topLessons,
        'topCategories': categoryCompletions.entries
            .map((e) => {'category_id': e.key, 'completions': e.value})
            .toList()
          ..sort((a, b) => (b['completions'] as int).compareTo(a['completions'] as int)),
        'usersByLanguage': usersByLanguage,
        'usersByLevel': usersByLevel,
        'usersByReason': usersByReason,
        'onboardingCompletionRate': onboardingCompletionRate,
      };
      
      developer.log('Analytics result: $result');
      return result;
    } catch (e, stackTrace) {
      developer.log('Failed to fetch analytics: $e');
      developer.log('Stack trace: $stackTrace');
      // Return partial data instead of throwing to show what we have
      return {
        'totalUsers': 0,
        'activeUsers': 0,
        'totalLessonsCompleted': 0,
        'topLessons': [],
        'topCategories': [],
        'usersByLanguage': {},
        'usersByLevel': {},
        'usersByReason': {},
        'onboardingCompletionRate': 0.0,
        'error': e.toString(),
      };
    }
  }

  // ============================================
  // NOTIFICATIONS
  // ============================================

  /// Send notification to all users
  static Future<void> sendBroadcastNotification({
    required String title,
    required String message,
    String type = 'info',
  }) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      await _client.from('notifications').insert({
        'user_id': null, // NULL = broadcast to all
        'title': title,
        'message': message,
        'type': type,
      });
    } catch (e) {
      throw Exception('Failed to send notification: $e');
    }
  }

  // ============================================
  // APP SETTINGS
  // ============================================

  /// Get app setting
  static Future<dynamic> getSetting(String key) async {
    if (SupabaseConfig.isDemoMode) return null;

    try {
      final response = await _client
          .from('app_settings')
          .select('value')
          .eq('key', key)
          .maybeSingle();

      return response?['value'];
    } catch (e) {
      return null;
    }
  }

  /// Update app setting
  static Future<void> updateSetting(String key, dynamic value) async {
    if (SupabaseConfig.isDemoMode) return;

    try {
      final userId = _client.auth.currentUser?.id;
      await _client
          .from('app_settings')
          .upsert({
            'key': key,
            'value': value,
            'updated_by': userId,
          });
    } catch (e) {
      throw Exception('Failed to update setting: $e');
    }
  }
}
