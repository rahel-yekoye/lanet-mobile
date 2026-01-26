// Admin dashboard models

class AdminUser {
  final String id;
  final String email;
  final String? name;
  final String role;
  final bool blocked;
  final String? preferredLanguage;
  final int lessonsCompleted;
  final int totalTimeSeconds;
  final DateTime? lastActivity;
  final DateTime joinedAt;

  AdminUser({
    required this.id,
    required this.email,
    this.name,
    required this.role,
    required this.blocked,
    this.preferredLanguage,
    required this.lessonsCompleted,
    required this.totalTimeSeconds,
    this.lastActivity,
    required this.joinedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      role: json['role'] as String? ?? 'user',
      blocked: json['blocked'] as bool? ?? false,
      preferredLanguage: json['language'] as String?,
      lessonsCompleted: json['lessons_completed'] as int? ?? 0,
      totalTimeSeconds: json['total_time_seconds'] as int? ?? 0,
      lastActivity: json['last_activity'] != null
          ? DateTime.parse(json['last_activity'] as String)
          : null,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class Lesson {
  final String id;
  final String title;
  final String? description;
  final String language;
  final String? categoryId;
  final String? category;
  final int difficulty;
  final String status;
  final int estimatedMinutes;
  final int orderIndex;
  final String? createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Exercise>? exercises;

  Lesson({
    required this.id,
    required this.title,
    this.description,
    required this.language,
    this.categoryId,
    this.category,
    required this.difficulty,
    required this.status,
    required this.estimatedMinutes,
    required this.orderIndex,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.exercises,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    // Helper to parse date safely
    DateTime parseDate(dynamic dateValue, DateTime fallback) {
      if (dateValue == null) return fallback;
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is DateTime) {
          return dateValue;
        }
      } catch (e) {
        // If parsing fails, return fallback
      }
      return fallback;
    }
    
    return Lesson(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      language: json['language'] as String? ?? 'Amharic',
      categoryId: json['category_id'] as String?,
      category: json['category'] as String?,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'draft',
      estimatedMinutes: (json['estimated_minutes'] as num?)?.toInt() ?? 5,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      createdBy: json['created_by'] as String?,
      createdAt: parseDate(json['created_at'], DateTime.now()),
      updatedAt: parseDate(json['updated_at'], DateTime.now()),
      exercises: json['exercises'] != null
          ? (json['exercises'] as List<dynamic>)
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'language': language,
      'category_id': categoryId,
      'category': category,
      'difficulty': difficulty,
      'status': status,
      'estimated_minutes': estimatedMinutes,
      'order_index': orderIndex,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (exercises != null)
        'exercises': exercises!.map((e) => e.toJson()).toList(),
    };
  }

  Lesson copyWith({
    String? id,
    String? title,
    String? description,
    String? language,
    String? categoryId,
    String? category,
    int? difficulty,
    String? status,
    int? estimatedMinutes,
    int? orderIndex,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Exercise>? exercises,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      language: language ?? this.language,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      orderIndex: orderIndex ?? this.orderIndex,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      exercises: exercises ?? this.exercises,
    );
  }
}

class Exercise {
  final String id;
  final String lessonId;
  final String type;
  final String prompt;
  final Map<String, dynamic>? options;
  final String correctAnswer;
  final int points;
  final String? mediaUrl;
  final int orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Exercise({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.prompt,
    this.options,
    required this.correctAnswer,
    required this.points,
    this.mediaUrl,
    required this.orderIndex,
    this.createdAt,
    this.updatedAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      type: json['type'] as String,
      prompt: json['prompt'] as String,
      options: json['options'] as Map<String, dynamic>?,
      correctAnswer: json['correct_answer'] as String,
      points: json['points'] as int? ?? 1,
      mediaUrl: json['media_url'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lesson_id': lessonId,
      'type': type,
      'prompt': prompt,
      'options': options,
      'correct_answer': correctAnswer,
      'points': points,
      'media_url': mediaUrl,
      'order_index': orderIndex,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  Exercise copyWith({
    String? id,
    String? lessonId,
    String? type,
    String? prompt,
    Map<String, dynamic>? options,
    String? correctAnswer,
    int? points,
    String? mediaUrl,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      type: type ?? this.type,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      points: points ?? this.points,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Helper to parse date safely
    DateTime parseDate(dynamic dateValue, DateTime fallback) {
      if (dateValue == null) return fallback;
      try {
        if (dateValue is String) {
          return DateTime.parse(dateValue);
        } else if (dateValue is DateTime) {
          return dateValue;
        }
      } catch (e) {
        // If parsing fails, return fallback
      }
      return fallback;
    }
    
    return Category(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(json['created_at'], DateTime.now()),
      updatedAt: parseDate(json['updated_at'], DateTime.now()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MediaAsset {
  final String id;
  final String storagePath;
  final String bucketName;
  final String fileName;
  final String fileType;
  final int? fileSize;
  final String? mimeType;
  final String? signedUrl;
  final DateTime? urlExpiresAt;
  final String? uploadedBy;
  final DateTime createdAt;

  MediaAsset({
    required this.id,
    required this.storagePath,
    required this.bucketName,
    required this.fileName,
    required this.fileType,
    this.fileSize,
    this.mimeType,
    this.signedUrl,
    this.urlExpiresAt,
    this.uploadedBy,
    required this.createdAt,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) {
    return MediaAsset(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      bucketName: json['bucket_name'] as String,
      fileName: json['file_name'] as String,
      fileType: json['file_type'] as String,
      fileSize: json['file_size'] as int?,
      mimeType: json['mime_type'] as String?,
      signedUrl: json['signed_url'] as String?,
      urlExpiresAt: json['url_expires_at'] != null
          ? DateTime.parse(json['url_expires_at'] as String)
          : null,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class AnalyticsData {
  final int totalUsers;
  final int activeUsers;
  final int premiumCount;
  final int totalLessonsCompleted;
  final List<LessonPopularity> topLessons;
  final double averageDailyTime;
  final double retentionRate;

  AnalyticsData({
    required this.totalUsers,
    required this.activeUsers,
    required this.premiumCount,
    required this.totalLessonsCompleted,
    required this.topLessons,
    required this.averageDailyTime,
    required this.retentionRate,
  });
}

class LessonPopularity {
  final String lessonId;
  final String title;
  final String category;
  final String language;
  final int completions;
  final double avgScore;
  final double avgTimeSeconds;

  LessonPopularity({
    required this.lessonId,
    required this.title,
    required this.category,
    required this.language,
    required this.completions,
    required this.avgScore,
    required this.avgTimeSeconds,
  });
}

