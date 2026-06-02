import 'package:hive/hive.dart';

part 'habit_model.g.dart';

@HiveType(typeId: 0)
class HabitModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime createdAt;

  @HiveField(3)
  final bool isCompleted;

  HabitModel({
    required this.id,
    required this.title,
    required this.createdAt,
    this.isCompleted = false,
  });
}