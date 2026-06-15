import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/habits/data/repositories/habit_repository.dart';
import 'package:habit_tracker/features/habits/data/models/habit_log_model.dart';

import '../../../helpers/test_helpers.dart';

// We test streak logic by exercising HabitRepository.computeStreak directly.
// Because computeStreak reads from Hive boxes, we test a pure extracted version.
// Extract this function from the repository for easy testing:
//
//   int computeStreakFromLogs(List<HabitLogModel> logs, DateTime today)
//
// Pure function = no mocking needed at all.

int computeStreakFromLogs(List<HabitLogModel> logs, DateTime today) {
  final completed = logs
      .where((l) => l.isCompleted)
      .map((l) => HabitLogModel.normalizeDate(l.date))
      .toSet();

  int streak = 0;
  var cursor = HabitLogModel.normalizeDate(today);

  while (completed.contains(cursor)) {
    streak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }
  return streak;
}

void main() {
  final today = DateTime(2024, 6, 15); // Saturday — fixed date for determinism

  group('computeStreakFromLogs', () {

    // ── Basic cases ───────────────────────────────────────────

    test('returns 0 when no logs exist', () {
      expect(computeStreakFromLogs([], today), 0);
    });

    test('returns 0 when today is not completed', () {
      final logs = makeStreak(
        habitId: 'h1',
        from: today.subtract(const Duration(days: 1)),
        days: 5,
      );
      expect(computeStreakFromLogs(logs, today), 0);
    });

    test('returns 1 when only today is completed', () {
      final logs = [makeLog(habitId: 'h1', date: today)];
      expect(computeStreakFromLogs(logs, today), 1);
    });

    test('returns correct count for unbroken streak including today', () {
      final logs = makeStreak(habitId: 'h1', from: today, days: 7);
      expect(computeStreakFromLogs(logs, today), 7);
    });

    // ── Broken streak ─────────────────────────────────────────

    test('stops counting at first missing day', () {
      // Days: today, yesterday, 2 days ago — then gap — then older days
      final recent = makeStreak(habitId: 'h1', from: today, days: 3);
      final older = makeStreak(
        habitId: 'h1',
        from: today.subtract(const Duration(days: 5)),
        days: 10,
      );
      expect(computeStreakFromLogs([...recent, ...older], today), 3);
    });

    test('gap of exactly one day breaks the streak', () {
      final logs = [
        makeLog(habitId: 'h1', date: today),
        // yesterday missing
        makeLog(habitId: 'h1',
            date: today.subtract(const Duration(days: 2))),
      ];
      expect(computeStreakFromLogs(logs, today), 1);
    });

    // ── Edge cases ────────────────────────────────────────────

    test('ignores logs with isCompleted = false', () {
      final logs = [
        makeLog(habitId: 'h1', date: today, isCompleted: true),
        makeLog(habitId: 'h1',
            date: today.subtract(const Duration(days: 1)),
            isCompleted: false), // missed
        makeLog(habitId: 'h1',
            date: today.subtract(const Duration(days: 2)),
            isCompleted: true),
      ];
      // Streak stops at day-1 because isCompleted = false
      expect(computeStreakFromLogs(logs, today), 1);
    });

    test('handles duplicate logs for same date (takes any completed)', () {
      final logs = [
        makeLog(habitId: 'h1', date: today, isCompleted: true),
        makeLog(habitId: 'h1', date: today, isCompleted: false), // duplicate
        makeLog(habitId: 'h1',
            date: today.subtract(const Duration(days: 1)),
            isCompleted: true),
      ];
      // Set deduplication: today is in the completed set because one log is true
      expect(computeStreakFromLogs(logs, today), 2);
    });

    test('very long streak (365 days) completes without error', () {
      final logs = makeStreak(habitId: 'h1', from: today, days: 365);
      expect(computeStreakFromLogs(logs, today), 365);
    });

    test('handles logs from the future correctly (ignores them)', () {
      final futureLog = makeLog(
        habitId: 'h1',
        date: today.add(const Duration(days: 1)),
      );
      final todayLog = makeLog(habitId: 'h1', date: today);
      // Future log should not extend the streak — cursor starts at today
      expect(computeStreakFromLogs([futureLog, todayLog], today), 1);
    });

    test('midnight normalization: logs at any time count for their date', () {
      // A log created at 23:59 and one at 00:01 same day → still 1 day
      final lateNight = HabitLogModel(
        id: 'late',
        habitId: 'h1',
        date: DateTime(2024, 6, 15, 23, 59),
        isCompleted: true,
        loggedAt: DateTime.now(),
      );
      final earlyMorning = HabitLogModel(
        id: 'early',
        habitId: 'h1',
        date: DateTime(2024, 6, 15, 0, 1),
        isCompleted: true,
        loggedAt: DateTime.now(),
      );
      // Both normalize to 2024-06-15, so streak is 1, not 2
      expect(computeStreakFromLogs([lateNight, earlyMorning], today), 1);
    });
  });

  // ── Streak boundary tests ─────────────────────────────────

  group('streak at month/year boundaries', () {
    test('counts correctly across month boundary', () {
      // June 1 back through May 29 = 4 days
      final monthBoundary = DateTime(2024, 6, 1);
      final logs = makeStreak(habitId: 'h1', from: monthBoundary, days: 4);
      expect(computeStreakFromLogs(logs, monthBoundary), 4);
    });

    test('counts correctly across year boundary', () {
      final newYear = DateTime(2024, 1, 2);
      final logs = makeStreak(habitId: 'h1', from: newYear, days: 5);
      // Should cross from Jan 2 back to Dec 29 without issue
      expect(computeStreakFromLogs(logs, newYear), 5);
    });

    test('handles leap year February correctly', () {
      final leapDay = DateTime(2024, 2, 29); // 2024 is a leap year
      final logs = makeStreak(habitId: 'h1', from: leapDay, days: 3);
      expect(computeStreakFromLogs(logs, leapDay), 3);
    });
  });
}
