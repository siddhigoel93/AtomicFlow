import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/models/habit_log_model.dart';
import 'package:habit_tracker/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:habit_tracker/features/habits/presentation/cubit/habit_state.dart';
import 'package:habit_tracker/core/notifications/notification_service.dart';

import '../../../helpers/mock_habit_repository.dart';
import '../../../helpers/test_helpers.dart';

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockHabitRepository repo;
  late MockNotificationService mockNotifications;

  setUpAll(() {
    registerFallbacks();
  });

  setUp(() {
    repo = MockHabitRepository();
    mockNotifications = MockNotificationService();

    // Default stub: most tests start with one habit, no logs
    when(() => repo.getHabits()).thenReturn([makeHabit()]);
    when(() => repo.getLogsForDate(any())).thenReturn([]);
    when(() => repo.computeStreak(any())).thenReturn(0);

    // Notification stubs
    when(() => mockNotifications.scheduleHabitReminder(any())).thenAnswer((_) async {});
    when(() => mockNotifications.cancelHabitReminder(any())).thenAnswer((_) async {});
  });

  HabitCubit makeCubit() => HabitCubit(
        repository: repo,
        notifications: mockNotifications,
      );

  // ── loadHabits ────────────────────────────────────────────────────────────

  group('loadHabits', () {
    blocTest<HabitCubit, HabitState>(
      'emits [Loading, Loaded] with habits and streaks',
      build: () {
        when(() => repo.computeStreak('habit-1')).thenReturn(5);
        return makeCubit();
      },
      act: (c) => c.loadHabits(),
      expect: () => [
        const HabitLoading(),
        isA<HabitLoaded>()
            .having((s) => s.habits.length, 'habit count', 1)
            .having((s) => s.streaks['habit-1'], 'streak', 5)
            .having((s) => s.todayLogs, 'no logs today', isEmpty),
      ],
      verify: (_) {
        verify(() => repo.getHabits()).called(1);
        verify(() => repo.getLogsForDate(any())).called(1);
      },
    );

    blocTest<HabitCubit, HabitState>(
      'emits [Loading, Loaded] with today logs when habit is done',
      build: () {
        final log = makeLog(habitId: 'habit-1', date: DateTime.now());
        when(() => repo.getLogsForDate(any())).thenReturn([log]);
        return makeCubit();
      },
      act: (c) => c.loadHabits(),
      expect: () => [
        const HabitLoading(),
        isA<HabitLoaded>()
            .having((s) => s.isCompletedToday('habit-1'), 'done today', true),
      ],
    );

    blocTest<HabitCubit, HabitState>(
      'emits [Loading, HabitError] when repository throws',
      build: () {
        when(() => repo.getHabits()).thenThrow(Exception('Hive read error'));
        return makeCubit();
      },
      act: (c) => c.loadHabits(),
      expect: () => [
        const HabitLoading(),
        isA<HabitError>().having(
            (s) => s.message, 'error message', contains('Hive read error')),
      ],
    );

    blocTest<HabitCubit, HabitState>(
      'emits [Loading, Loaded] with empty list when no habits',
      build: () {
        when(() => repo.getHabits()).thenReturn([]);
        return makeCubit();
      },
      act: (c) => c.loadHabits(),
      expect: () => [
        const HabitLoading(),
        isA<HabitLoaded>().having((s) => s.habits, 'empty', isEmpty),
      ],
    );
  });

  // ── addHabit ──────────────────────────────────────────────────────────────

  group('addHabit', () {
    blocTest<HabitCubit, HabitState>(
      'saves habit and emits refreshed Loaded state',
      build: () {
        when(() => repo.saveHabit(any())).thenAnswer((_) async {});
        return makeCubit();
      },
      act: (c) => c.addHabit(makeHabit(name: 'Meditate')),
      expect: () => [
        isA<HabitLoaded>().having((s) => s.habits.length, 'count', 1),
      ],
      verify: (_) => verify(() => repo.saveHabit(any())).called(1),
    );

    blocTest<HabitCubit, HabitState>(
      'emits HabitError when saveHabit throws',
      build: () {
        when(() => repo.saveHabit(any())).thenThrow(Exception('write fail'));
        return makeCubit();
      },
      act: (c) => c.addHabit(makeHabit()),
      expect: () => [isA<HabitError>()],
    );
  });

  // ── deleteHabit ───────────────────────────────────────────────────────────

  group('deleteHabit', () {
    blocTest<HabitCubit, HabitState>(
      'deletes habit and emits Loaded with empty list',
      build: () {
        when(() => repo.getHabitById('habit-1')).thenReturn(makeHabit());
        when(() => repo.deleteHabit('habit-1')).thenAnswer((_) async {});
        when(() => repo.getHabits()).thenReturn([]); // gone after delete
        return makeCubit();
      },
      act: (c) => c.deleteHabit('habit-1'),
      expect: () => [
        isA<HabitLoaded>().having((s) => s.habits, 'empty', isEmpty),
      ],
      verify: (_) => verify(() => repo.deleteHabit('habit-1')).called(1),
    );
  });

  // ── toggleCompletion ──────────────────────────────────────────────────────

  group('toggleCompletion', () {
    blocTest<HabitCubit, HabitState>(
      'emits optimistic state then reconciles — marking done',
      build: () {
        when(() => repo.toggleCompletion(any(), any()))
            .thenAnswer((_) async {});
        final log = makeLog(habitId: 'habit-1', date: DateTime.now());
        when(() => repo.getLogsForDate(any())).thenReturn([log]);
        when(() => repo.computeStreak('habit-1')).thenReturn(1);
        return makeCubit()
          ..emit(HabitLoaded(
            habits: [makeHabit()],
            todayLogs: [],
            streaks: {'habit-1': 0},
          ));
      },
      act: (c) => c.toggleCompletion('habit-1'),
      expect: () => [
        // 1st emit: optimistic
        isA<HabitLoaded>().having(
            (s) => s.isCompletedToday('habit-1'), 'optimistic done', true),
        // 2nd emit: reconciled with streak
        isA<HabitLoaded>()
            .having((s) => s.streaks['habit-1'], 'streak reconciled', 1),
      ],
    );

    blocTest<HabitCubit, HabitState>(
      'emits optimistic state removing log when already done',
      build: () {
        when(() => repo.toggleCompletion(any(), any()))
            .thenAnswer((_) async {});
        when(() => repo.getLogsForDate(any())).thenReturn([]);
        return makeCubit()
          ..emit(HabitLoaded(
            habits: [makeHabit()],
            todayLogs: [makeLog(habitId: 'habit-1', date: DateTime.now())],
            streaks: {'habit-1': 3},
          ));
      },
      act: (c) => c.toggleCompletion('habit-1'),
      expect: () => [
        isA<HabitLoaded>().having(
            (s) => s.isCompletedToday('habit-1'), 'optimistic undone', false),
        isA<HabitLoaded>(),
      ],
    );
  });

  // ── HabitLoaded helpers ───────────────────────────────────────────────────

  group('HabitLoaded.isCompletedToday', () {
    test('true when completed log exists for habit', () {
      final state = HabitLoaded(
        habits: [],
        todayLogs: [makeLog(habitId: 'h1', date: DateTime.now())],
        streaks: {},
      );
      expect(state.isCompletedToday('h1'), isTrue);
    });

    test('false when no log for habit', () {
      final state = HabitLoaded(habits: [], todayLogs: [], streaks: {});
      expect(state.isCompletedToday('h1'), isFalse);
    });

    test('false when log exists but isCompleted = false', () {
      final state = HabitLoaded(
        habits: [],
        todayLogs: [
          makeLog(habitId: 'h1', date: DateTime.now(), isCompleted: false)
        ],
        streaks: {},
      );
      expect(state.isCompletedToday('h1'), isFalse);
    });

    test('false when log is for a different habit', () {
      final state = HabitLoaded(
        habits: [],
        todayLogs: [makeLog(habitId: 'h2', date: DateTime.now())],
        streaks: {},
      );
      expect(state.isCompletedToday('h1'), isFalse);
    });
  });
}
