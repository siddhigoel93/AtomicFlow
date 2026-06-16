import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';         // add hive_test to dev_deps

import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/models/habit_log_model.dart';
import 'package:habit_tracker/features/habits/data/repositories/habit_repository.dart';
import 'package:habit_tracker/core/hive_boxes.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    Hive.registerAdapter(HabitModelAdapter());
    Hive.registerAdapter(HabitFrequencyAdapter());
    Hive.registerAdapter(HabitLogModelAdapter());
  });

  setUp(() async {
    await setUpTestHive();
    await Hive.openBox<HabitModel>(HiveBoxes.habits);
    await Hive.openBox<HabitLogModel>(HiveBoxes.habitLogs);
  });

  tearDown(() async => await tearDownTestHive());

  HabitRepository makeRepo() => HabitRepository();

  group('HabitRepository CRUD', () {
    test('saveHabit persists and getHabits returns it', () async {
      final repo = makeRepo();
      final habit = makeHabit(name: 'Meditate');

      await repo.saveHabit(habit);

      final habits = repo.getHabits();
      expect(habits.length, 1);
      expect(habits.first.name, 'Meditate');
    });

    test('getHabits excludes archived habits by default', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit(id: 'h1'));
      await repo.saveHabit(makeHabit(id: 'h2', isArchived: true));

      expect(repo.getHabits().length, 1);
      expect(repo.getHabits(includeArchived: true).length, 2);
    });

    test('deleteHabit removes habit and its logs', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit());
      await repo.toggleCompletion('habit-1', DateTime.now());

      await repo.deleteHabit('habit-1');

      expect(repo.getHabits(), isEmpty);
      expect(repo.getLogsForHabit('habit-1'), isEmpty);
    });

    test('archiveHabit sets isArchived = true', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit());
      await repo.archiveHabit('habit-1');

      final habits = repo.getHabits(includeArchived: true);
      expect(habits.first.isArchived, isTrue);
    });
  });

  group('HabitRepository log operations', () {
    test('toggleCompletion creates log on first tap', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit());

      await repo.toggleCompletion('habit-1', DateTime.now());

      final log = repo.getLogForDate('habit-1',
          HabitLogModel.normalizeDate(DateTime.now()));
      expect(log, isNotNull);
      expect(log!.isCompleted, isTrue);
    });

    test('toggleCompletion flips existing log', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit());
      await repo.toggleCompletion('habit-1', DateTime.now());

      await repo.toggleCompletion('habit-1', DateTime.now()); // second tap

      final log = repo.getLogForDate('habit-1',
          HabitLogModel.normalizeDate(DateTime.now()));
      expect(log!.isCompleted, isFalse);
    });

    test('getLogsForDate returns only logs for that calendar day', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit());

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));

      await repo.toggleCompletion('habit-1', today);
      await repo.toggleCompletion('habit-1', yesterday);

      final todayLogs = repo.getLogsForDate(today);
      expect(todayLogs.length, 1);
    });
  });

  group('HabitRepository.computeStreak', () {
    test('returns 0 when no logs', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit());
      expect(repo.computeStreak('habit-1'), 0);
    });

    test('returns correct streak for consecutive days', () async {
      final repo = makeRepo();
      await repo.saveHabit(makeHabit());

      final today = DateTime.now();
      for (int i = 0; i < 5; i++) {
        await repo.toggleCompletion(
            'habit-1', today.subtract(Duration(days: i)));
      }

      expect(repo.computeStreak('habit-1'), 5);
    });
  });
}
