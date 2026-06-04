import 'package:equatable/equatable.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_log_model.dart';

sealed class HabitState extends Equatable {
  const HabitState();

  @override
  List<Object?> get props => [];
}

final class HabitInitial extends HabitState {
  const HabitInitial();
}

final class HabitLoading extends HabitState {
  const HabitLoading();
}

final class HabitLoaded extends HabitState {
  final List<HabitModel> habits;
  final List<HabitLogModel> todayLogs;
  final Map<String, int> streaks;

  const HabitLoaded({
    required this.habits,
    required this.todayLogs,
    required this.streaks,
  });

  bool isCompletedToday(String habitId) =>
      todayLogs.any((l) => l.habitId == habitId && l.isCompleted);

  HabitLoaded copyWith({
    List<HabitModel>? habits,
    List<HabitLogModel>? todayLogs,
    Map<String, int>? streaks,
  }) {
    return HabitLoaded(
      habits: habits ?? this.habits,
      todayLogs: todayLogs ?? this.todayLogs,
      streaks: streaks ?? this.streaks,
    );
  }

  @override
  List<Object?> get props => [habits, todayLogs, streaks];
}

final class HabitError extends HabitState {
  final String message;

  const HabitError(this.message);

  @override
  List<Object?> get props => [message];
}
