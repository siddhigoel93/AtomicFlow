import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int iconCode;

  @HiveField(3)
  final String colorHex;

  @HiveField(4)
  final HabitFrequency frequency;

  @HiveField(5)
  final List<int> weekdays;

  @HiveField(6)
  final String? reminderTime;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final bool isArchived;

  HabitModel({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorHex,
    required this.frequency,
    required this.weekdays,
    this.reminderTime,
    required this.createdAt,
    this.isArchived = false,
  });

  HabitModel copyWith({
    String? name,
    int? iconCode,
    String? colorHex,
    HabitFrequency? frequency,
    List<int>? weekdays,
    String? reminderTime,
    bool? isArchived,
  }) {
    return HabitModel(
      id: id,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      colorHex: colorHex ?? this.colorHex,
      frequency: frequency ?? this.frequency,
      weekdays: weekdays ?? this.weekdays,
      reminderTime: reminderTime ?? this.reminderTime,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  @override
  String toString() =>
      'HabitModel(id: $id, name: $name, frequency: $frequency)';
}

@HiveType(typeId: 1)
enum HabitFrequency {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,
}