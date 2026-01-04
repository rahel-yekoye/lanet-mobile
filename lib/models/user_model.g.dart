// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      id: fields[0] as String,
      name: fields[1] as String,
      avatarUrl: fields[2] as String?,
      xp: fields[3] as int,
      level: fields[4] as int,
      streak: fields[5] as int,
      lastActiveDate: fields[6] as DateTime?,
      dailyGoal: fields[7] as int,
      dailyXpEarned: fields[8] as int,
      settings: (fields[9] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarUrl)
      ..writeByte(3)
      ..write(obj.xp)
      ..writeByte(4)
      ..write(obj.level)
      ..writeByte(5)
      ..write(obj.streak)
      ..writeByte(6)
      ..write(obj.lastActiveDate)
      ..writeByte(7)
      ..write(obj.dailyGoal)
      ..writeByte(8)
      ..write(obj.dailyXpEarned)
      ..writeByte(9)
      ..write(obj.settings);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 1,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['lastActiveDate'] == null
          ? null
          : DateTime.parse(json['lastActiveDate'] as String),
      dailyGoal: (json['dailyGoal'] as num?)?.toInt() ?? 100,
      dailyXpEarned: (json['dailyXpEarned'] as num?)?.toInt() ?? 0,
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'avatarUrl': instance.avatarUrl,
      'xp': instance.xp,
      'level': instance.level,
      'streak': instance.streak,
      'lastActiveDate': instance.lastActiveDate.toIso8601String(),
      'dailyGoal': instance.dailyGoal,
      'dailyXpEarned': instance.dailyXpEarned,
      'settings': instance.settings,
    };
