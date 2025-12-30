import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'achievement_model.g.dart';

@HiveType(typeId: 5)
enum AchievementType {
  @HiveField(0)
  streak,
  @HiveField(1)
  xp,
  @HiveField(2)
  lessonsCompleted,
  @HiveField(3)
  perfectLessons,
  @HiveField(4)
  dailyGoal,
  @HiveField(5)
  special,
}

@HiveType(typeId: 4)
class Achievement extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String icon;
  
  @HiveField(4)
  final AchievementType type;
  
  @HiveField(5)
  final int targetValue;
  
  @HiveField(6)
  final int currentValue;
  
  @HiveField(7)
  final bool isUnlocked;
  
  @HiveField(8)
  final DateTime? unlockedAt;
  
  @HiveField(9)
  final int xpReward;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.targetValue,
    this.currentValue = 0,
    this.isUnlocked = false,
    this.unlockedAt,
    this.xpReward = 0,
  });

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    int? targetValue,
    int? currentValue,
    bool? isUnlocked,
    DateTime? unlockedAt,
    int? xpReward,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  Achievement updateProgress(int newValue) {
    final isNowUnlocked = newValue >= targetValue;
    return copyWith(
      currentValue: newValue,
      isUnlocked: isNowUnlocked || isUnlocked,
      unlockedAt: isNowUnlocked && !isUnlocked ? DateTime.now() : unlockedAt,
    );
  }

  double get progress => isUnlocked ? 1.0 : (currentValue / targetValue).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        type,
        targetValue,
        currentValue,
        isUnlocked,
        unlockedAt,
        xpReward,
      ];
}
