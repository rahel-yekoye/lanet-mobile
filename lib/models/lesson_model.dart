import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'lesson_model.g.dart';

enum LessonType { vocabulary, grammar, listening, speaking, review }

@HiveType(typeId: 2)
class Lesson extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String unitId;
  
  @HiveField(2)
  final String title;
  
  @HiveField(3)
  final String description;
  
  @HiveField(4)
  final LessonType type;
  
  @HiveField(5)
  final int order;
  
  @HiveField(6)
  final bool isCompleted;
  
  @HiveField(7)
  final bool isLocked;
  
  @HiveField(8)
  final int xpReward;
  
  @HiveField(9)
  final List<String> contentIds;

  const Lesson({
    required this.id,
    required this.unitId,
    required this.title,
    required this.description,
    required this.type,
    required this.order,
    this.isCompleted = false,
    this.isLocked = true,
    this.xpReward = 5,
    this.contentIds = const [],
  });

  Lesson copyWith({
    String? id,
    String? unitId,
    String? title,
    String? description,
    LessonType? type,
    int? order,
    bool? isCompleted,
    bool? isLocked,
    int? xpReward,
    List<String>? contentIds,
  }) {
    return Lesson(
      id: id ?? this.id,
      unitId: unitId ?? this.unitId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
      xpReward: xpReward ?? this.xpReward,
      contentIds: contentIds ?? List.from(this.contentIds),
    );
  }

  @override
  List<Object?> get props => [
        id,
        unitId,
        title,
        description,
        type,
        order,
        isCompleted,
        isLocked,
        xpReward,
        contentIds,
      ];
}
