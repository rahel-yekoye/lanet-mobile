import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'content_model.g.dart';

@HiveType(typeId: 10) // Make sure this typeId is unique
enum ContentType {
  @HiveField(0)
  flashcard,
  @HiveField(1)
  multipleChoice,
  @HiveField(2)
  fillInBlank,
  @HiveField(3)
  listening,
  @HiveField(4)
  speaking,
  @HiveField(5)
  matching,
  @HiveField(6)
  reorder,
}

@HiveType(typeId: 3)
class Content extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String lessonId;
  
  @HiveField(2)
  final ContentType type;
  
  @HiveField(3)
  final Map<String, dynamic> data;
  
  @HiveField(4)
  final int order;
  
  @HiveField(5)
  final bool isCompleted;
  
  @HiveField(6)
  final int xpReward;

  const Content({
    required this.id,
    required this.lessonId,
    required this.type,
    required this.data,
    required this.order,
    this.isCompleted = false,
    this.xpReward = 1,
  });

  Content copyWith({
    String? id,
    String? lessonId,
    ContentType? type,
    Map<String, dynamic>? data,
    int? order,
    bool? isCompleted,
    int? xpReward,
  }) {
    return Content(
      id: id ?? this.id,
      lessonId: lessonId ?? this.lessonId,
      type: type ?? this.type,
      data: data ?? Map.from(this.data),
      order: order ?? this.order,
      isCompleted: isCompleted ?? this.isCompleted,
      xpReward: xpReward ?? this.xpReward,
    );
  }

  @override
  List<Object?> get props => [
        id,
        lessonId,
        type,
        data,
        order,
        isCompleted,
        xpReward,
      ];
}
