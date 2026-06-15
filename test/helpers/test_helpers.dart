import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/data/models/habit_log_model.dart';
import 'package:habit_tracker/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:habit_tracker/features/habits/presentation/cubit/habit_state.dart';

// ── Model factories ───────────────────────────────────────────────────────────
// Named parameters let each test override only what it cares about.

HabitModel makeHabit({
  String id = 'habit-1',
  String name = 'Read',
  HabitFrequency frequency = HabitFrequency.daily,
  List<int> weekdays = const [],
  String? reminderTime,
  bool isArchived = false,
}) =>
    HabitModel(
      id: id,
      name: name,
      iconCode: 0xe3af,
      colorHex: '#7F77DD',
      frequency: frequency,
      weekdays: weekdays,
      reminderTime: reminderTime,
      createdAt: DateTime(2024, 1, 1),
      isArchived: isArchived,
    );

HabitLogModel makeLog({
  required String habitId,
  required DateTime date,
  bool isCompleted = true,
}) =>
    HabitLogModel(
      id: '${habitId}_${date.millisecondsSinceEpoch}',
      habitId: habitId,
      date: HabitLogModel.normalizeDate(date),
      isCompleted: isCompleted,
      loggedAt: DateTime.now(),
    );

/// Builds consecutive completed logs going back [days] from [from].
List<HabitLogModel> makeStreak({
  required String habitId,
  required DateTime from,
  required int days,
}) =>
    List.generate(days, (i) {
      final date = from.subtract(Duration(days: i));
      return makeLog(habitId: habitId, date: date);
    });

// ── Widget pump helper ────────────────────────────────────────────────────────
// Every widget test needs a MaterialApp + BlocProvider. Put it here once.

Future<void> pumpWithCubit(
  WidgetTester tester,
  Widget child,
  HabitCubit cubit,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<HabitCubit>.value(
        value: cubit,
        child: Scaffold(body: child),
      ),
    ),
  );
}

/// Pumps and settles, then pumps one extra frame to flush animations.
Future<void> pumpAndSettle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
}
