import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_log_model.dart';
import '../../data/repositories/habit_repository.dart';
import 'habit_state.dart';

class HabitCubit extends Cubit<HabitState> {
  final HabitRepository _repository;

  HabitCubit({required HabitRepository repository})
      : _repository = repository,
        super(const HabitInitial());

  Future<void> loadHabits() async {
    emit(const HabitLoading());
    try {
      final habits = _repository.getHabits();
      final todayLogs = _repository.getLogsForDate(DateTime.now());
      final streaks = {
        for (final h in habits) h.id: _repository.computeStreak(h.id),
      };

      emit(HabitLoaded(
        habits: habits,
        todayLogs: todayLogs,
        streaks: streaks,
      ));
    } catch (e) {
      emit(HabitError('Failed to load habits: $e'));
    }
  }

  Future<void> addHabit(HabitModel habit) async {
    try {
      await _repository.saveHabit(habit);
      await _refreshLoaded();
    } catch (e) {
      emit(HabitError('Failed to add habit: $e'));
    }
  }

  Future<void> updateHabit(HabitModel updated) async {
    try {
      await _repository.saveHabit(updated);
      await _refreshLoaded();
    } catch (e) {
      emit(HabitError('Failed to update habit: $e'));
    }
  }

  Future<void> deleteHabit(String habitId) async {
    try {
      await _repository.deleteHabit(habitId);
      await _refreshLoaded();
    } catch (e) {
      emit(HabitError('Failed to delete habit: $e'));
    }
  }

  Future<void> toggleCompletion(String habitId) async {
    if (state is HabitLoaded) {
      final current = state as HabitLoaded;
      final alreadyDone = current.isCompletedToday(habitId);

      final optimisticLogs = alreadyDone
          ? current.todayLogs
              .where((l) => !(l.habitId == habitId && l.isCompleted))
              .toList()
          : [
              ...current.todayLogs,
              HabitLogModel(
                id: '${habitId}_optimistic',
                habitId: habitId,
                date: HabitLogModel.normalizeDate(DateTime.now()),
                isCompleted: true,
                loggedAt: DateTime.now(),
              ),
            ];

      emit(current.copyWith(todayLogs: optimisticLogs));
    }

    try {
      await _repository.toggleCompletion(habitId, DateTime.now());
      await _refreshLoaded();
    } catch (e) {
      emit(HabitError('Failed to toggle habit: $e'));
    }
  }

  Future<void> archiveHabit(String habitId) async {
    try {
      await _repository.archiveHabit(habitId);
      await _refreshLoaded();
    } catch (e) {
      emit(HabitError('Failed to archive habit: $e'));
    }
  }

  Future<void> _refreshLoaded() async {
    final habits = _repository.getHabits();
    final todayLogs = _repository.getLogsForDate(DateTime.now());
    final streaks = {
      for (final h in habits) h.id: _repository.computeStreak(h.id),
    };

    emit(HabitLoaded(
      habits: habits,
      todayLogs: todayLogs,
      streaks: streaks,
    ));
  }
}
