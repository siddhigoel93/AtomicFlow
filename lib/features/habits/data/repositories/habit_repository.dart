import 'package:hive/hive.dart';
import '../models/habit_model.dart';
import '../models/habit_log_model.dart';
import '../../../../core/hive_boxes.dart';

class HabitRepository {
  Box<HabitModel> get _habits => Hive.box<HabitModel>(HiveBoxes.habits);
  Box<HabitLogModel> get _logs => Hive.box<HabitLogModel>(HiveBoxes.habitLogs);

  Future<void> saveHabit(HabitModel habit) async {
    await _habits.put(habit.id, habit);
  }

  List<HabitModel> getHabits({bool includeArchived = false}) {
    return _habits.values
        .where((h) => includeArchived || !h.isArchived)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  HabitModel? getHabitById(String id) => _habits.get(id);

  Future<void> deleteHabit(String id) async {
    await _habits.delete(id);
    final toDelete = _logs.values
        .where((log) => log.habitId == id)
        .map((log) => log.id)
        .toList();
    await _logs.deleteAll(toDelete);
  }

  Future<void> archiveHabit(String id) async {
    final habit = _habits.get(id);
    if (habit == null) return;
    await _habits.put(id, habit.copyWith(isArchived: true));
  }

  Future<void> toggleCompletion(String habitId, DateTime date) async {
    final normalized = HabitLogModel.normalizeDate(date);
    final existing = getLogForDate(habitId, normalized);

    if (existing != null) {
      await _logs.put(
        existing.id,
        existing.copyWith(
          isCompleted: !existing.isCompleted,
          loggedAt: DateTime.now(),
        ),
      );
    } else {
      final log = HabitLogModel(
        id: '${habitId}_${normalized.millisecondsSinceEpoch}',
        habitId: habitId,
        date: normalized,
        isCompleted: true,
        loggedAt: DateTime.now(),
      );
      await _logs.put(log.id, log);
    }
  }

  HabitLogModel? getLogForDate(String habitId, DateTime date) {
    final normalized = HabitLogModel.normalizeDate(date);
    try {
      return _logs.values.firstWhere(
        (log) => log.habitId == habitId && log.date == normalized,
      );
    } catch (_) {
      return null;
    }
  }

  List<HabitLogModel> getLogsForHabit(String habitId) {
    return _logs.values
        .where((log) => log.habitId == habitId)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<HabitLogModel> getLogsForDate(DateTime date) {
    final normalized = HabitLogModel.normalizeDate(date);
    return _logs.values
        .where((log) => log.date == normalized && log.isCompleted)
        .toList();
  }

  List<HabitLogModel> getAllLogs() {
    return _logs.values.toList();
  }

  int computeStreak(String habitId) {
    final logs = getLogsForHabit(habitId)
        .where((l) => l.isCompleted)
        .map((l) => l.date)
        .toSet();

    int streak = 0;
    DateTime cursor = HabitLogModel.normalizeDate(DateTime.now());

    while (logs.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
