import 'package:hive/hive.dart';

part 'habit_log_model.g.dart';

@HiveType(typeId: 2)
class HabitLogModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String habitId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final DateTime loggedAt;

  HabitLogModel({
    required this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    required this.loggedAt,
  });

  static DateTime normalizeDate(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  HabitLogModel copyWith({bool? isCompleted, DateTime? loggedAt}) {
    return HabitLogModel(
      id: id,
      habitId: habitId,
      date: date,
      isCompleted: isCompleted ?? this.isCompleted,
      loggedAt: loggedAt ?? this.loggedAt,
    );
  }

  @override
  String toString() =>
      'HabitLogModel(habitId: $habitId, date: $date, completed: $isCompleted)';
}
