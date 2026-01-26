import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final String id;
  final String userId;
  final String preferredLanguage;
  final String proficiencyLevel;
  final List<String> learningReasons;
  final int dailyGoalMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserPreferences({
    required this.id,
    required this.userId,
    required this.preferredLanguage,
    required this.proficiencyLevel,
    required this.learningReasons,
    required this.dailyGoalMinutes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      preferredLanguage: json['preferred_language'] as String,
      proficiencyLevel: json['proficiency_level'] as String,
      learningReasons: (json['learning_reasons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      dailyGoalMinutes: json['daily_goal_minutes'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'preferred_language': preferredLanguage,
      'proficiency_level': proficiencyLevel,
      'learning_reasons': learningReasons,
      'daily_goal_minutes': dailyGoalMinutes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserPreferences copyWith({
    String? id,
    String? userId,
    String? preferredLanguage,
    String? proficiencyLevel,
    List<String>? learningReasons,
    int? dailyGoalMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      proficiencyLevel: proficiencyLevel ?? this.proficiencyLevel,
      learningReasons: learningReasons ?? this.learningReasons,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper to get difficulty level as integer
  int get difficultyLevel {
    switch (proficiencyLevel) {
      case 'Beginner':
        return 1;
      case 'Intermediate':
        return 2;
      case 'Advanced':
        return 3;
      default:
        return 1;
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        preferredLanguage,
        proficiencyLevel,
        learningReasons,
        dailyGoalMinutes,
        createdAt,
        updatedAt,
      ];
}

