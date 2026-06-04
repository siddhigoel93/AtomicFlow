// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class HabitLogModelAdapter extends TypeAdapter<HabitLogModel> {
  @override
  final int typeId = 2;

  @override
  HabitLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HabitLogModel(
      id: fields[0] as String,
      habitId: fields[1] as String,
      date: fields[2] as DateTime,
      isCompleted: fields[3] as bool,
      loggedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, HabitLogModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.habitId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.isCompleted)
      ..writeByte(4)
      ..write(obj.loggedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
