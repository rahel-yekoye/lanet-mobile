import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()

@HiveType(typeId: 0)
class User extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? avatarUrl;
  
  @HiveField(3)
  final int xp;
  
  @HiveField(4)
  final int level;
  
  @HiveField(5)
  final int streak;
  
  @HiveField(6)
  final DateTime lastActiveDate;
  
  @HiveField(7)
  final int dailyGoal;
  
  @HiveField(8)
  final int dailyXpEarned;
  
  @HiveField(9)
  final Map<String, dynamic> settings;

  User({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.xp = 0,
    this.level = 1,
    this.streak = 0,
    DateTime? lastActiveDate,
    this.dailyGoal = 100,
    this.dailyXpEarned = 0,
    Map<String, dynamic>? settings,
  }) : lastActiveDate = lastActiveDate ?? DateTime.now(),
       settings = settings ?? {};

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    int? xp,
    int? level,
    int? streak,
    DateTime? lastActiveDate,
    int? dailyGoal,
    int? dailyXpEarned,
    Map<String, dynamic>? settings,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      dailyXpEarned: dailyXpEarned ?? this.dailyXpEarned,
      settings: settings ?? Map.from(this.settings),
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        avatarUrl,
        xp,
        level,
        streak,
        lastActiveDate,
        dailyGoal,
        dailyXpEarned,
        settings,
      ];
}
