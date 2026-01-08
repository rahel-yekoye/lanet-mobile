// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ContentAdapter extends TypeAdapter<Content> {
  @override
  final int typeId = 3;

  @override
  Content read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Content(
      id: fields[0] as String,
      lessonId: fields[1] as String,
      type: fields[2] as ContentType,
      data: (fields[3] as Map).cast<String, dynamic>(),
      order: fields[4] as int,
      isCompleted: fields[5] as bool,
      xpReward: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Content obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.lessonId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.order)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.xpReward);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContentTypeAdapter extends TypeAdapter<ContentType> {
  @override
  final int typeId = 10;

  @override
  ContentType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ContentType.flashcard;
      case 1:
        return ContentType.multipleChoice;
      case 2:
        return ContentType.fillInBlank;
      case 3:
        return ContentType.listening;
      case 4:
        return ContentType.speaking;
      case 5:
        return ContentType.matching;
      case 6:
        return ContentType.reorder;
      default:
        return ContentType.flashcard;
    }
  }

  @override
  void write(BinaryWriter writer, ContentType obj) {
    switch (obj) {
      case ContentType.flashcard:
        writer.writeByte(0);
        break;
      case ContentType.multipleChoice:
        writer.writeByte(1);
        break;
      case ContentType.fillInBlank:
        writer.writeByte(2);
        break;
      case ContentType.listening:
        writer.writeByte(3);
        break;
      case ContentType.speaking:
        writer.writeByte(4);
        break;
      case ContentType.matching:
        writer.writeByte(5);
        break;
      case ContentType.reorder:
        writer.writeByte(6);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
