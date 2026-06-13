import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../habits/data/repositories/habit_repository.dart';

class StatsCubit extends Cubit<void> {
  final HabitRepository _repository;

  StatsCubit({required HabitRepository repository})
      : _repository = repository,
        super(null);

  Map<DateTime, bool> getHeatmapData(String habitId, {int days = 126}) {
    final logs = _repository.getLogsForHabit(habitId);
    final logMap = {for (final l in logs) l.date: l.isCompleted};

    final today = DateTime.now();
    final result = <DateTime, bool>{};

    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime(today.year, today.month, today.day - i);
      // Only include dates that have a log entry — absent = no data
      if (logMap.containsKey(date)) {
        result[date] = logMap[date]!;
      }
    }
    return result;
  }
}
