import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'unit_model.g.dart';

@HiveType(typeId: 1)
class Unit extends Equatable {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final String icon;
  
  @HiveField(4)
  final int order;
  
  @HiveField(5)
  final bool isLocked;
  
  @HiveField(6)
  final List<String> lessonIds;
  
  @HiveField(7)
  final int xpReward;

  const Unit({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.order,
    this.isLocked = true,
    this.lessonIds = const [],
    this.xpReward = 10,
  });

  Unit copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    int? order,
    bool? isLocked,
    List<String>? lessonIds,
    int? xpReward,
  }) {
    return Unit(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      order: order ?? this.order,
      isLocked: isLocked ?? this.isLocked,
      lessonIds: lessonIds ?? List.from(this.lessonIds),
      xpReward: xpReward ?? this.xpReward,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        icon,
        order,
        isLocked,
        lessonIds,
        xpReward,
      ];
}
