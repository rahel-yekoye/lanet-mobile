import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

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
  final DateTime? lastActiveDate;

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
  })  : lastActiveDate = lastActiveDate ?? DateTime.now(),
        settings = settings ?? {};

  factory User.fromJson(Map<String, dynamic> json) {
    int _asInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    int _parseLevel(dynamic v) {
      if (v is int) return v;
      if (v is String) {
        final s = v.toLowerCase();
        if (s.startsWith('begin')) return 1;
        if (s.startsWith('inter')) return 2;
        if (s.startsWith('adv')) return 3;
        return int.tryParse(s) ?? 1;
      }
      return 1;
    }

    DateTime? _parseDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    final dailyGoalRaw = json['dailyGoal'] ?? json['daily_goal'];
    final dailyXpRaw = json['dailyXpEarned'] ?? json['daily_xp_earned'];
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      xp: _asInt(json['xp']),
      level: _parseLevel(json['level']),
      streak: _asInt(json['streak']),
      lastActiveDate: _parseDate(json['lastActiveDate']) ?? DateTime.now(),
      dailyGoal: _asInt(dailyGoalRaw),
      dailyXpEarned: _asInt(dailyXpRaw),
      settings: (json['settings'] as Map<dynamic, dynamic>?)
              ?.cast<String, dynamic>() ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatarUrl': avatarUrl,
      'xp': xp,
      'level': level,
      'streak': streak,
      'lastActiveDate': lastActiveDate?.toIso8601String(),
      'dailyGoal': dailyGoal,
      'dailyXpEarned': dailyXpEarned,
      'settings': settings.cast<String, dynamic>(),
    };
  }

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
