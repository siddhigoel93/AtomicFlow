import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:habit_tracker/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:habit_tracker/features/habits/presentation/cubit/habit_state.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/habit_tile.dart';

import '../../../helpers/mock_habit_repository.dart';
import '../../../helpers/test_helpers.dart';

class MockHabitCubit extends MockCubit<HabitState> implements HabitCubit {}

void main() {
  late MockHabitCubit cubit;

  setUpAll(registerFallbacks);

  setUp(() => cubit = MockHabitCubit());

  Future<void> pumpTile(
    WidgetTester tester, {
    required HabitState state,
  }) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, Stream.value(state));

    await pumpWithCubit(
      tester,
      HabitTile(habit: makeHabit()),
      cubit,
    );
    await tester.pump();
  }

  HabitLoaded loadedState({bool done = false, int streak = 0}) => HabitLoaded(
        habits: [makeHabit()],
        todayLogs: done
            ? [makeLog(habitId: 'habit-1', date: DateTime.now())]
            : [],
        streaks: {'habit-1': streak},
      );

  // ── Rendering ─────────────────────────────────────────────────────────────

  group('HabitTile rendering', () {
    testWidgets('shows habit name', (tester) async {
      await pumpTile(tester, state: loadedState());
      expect(find.text('Read'), findsOneWidget);
    });

    testWidgets('shows streak badge when streak > 0', (tester) async {
      await pumpTile(tester, state: loadedState(streak: 5));
      expect(find.text('5 day streak'), findsOneWidget);
    });

    testWidgets('hides streak badge when streak is 0', (tester) async {
      await pumpTile(tester, state: loadedState(streak: 0));
      expect(find.textContaining('streak'), findsNothing);
    });

    testWidgets('shows check icon when done', (tester) async {
      await pumpTile(tester, state: loadedState(done: true));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('hides check icon when not done', (tester) async {
      await pumpTile(tester, state: loadedState(done: false));
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('shows strikethrough text when done', (tester) async {
      await pumpTile(tester, state: loadedState(done: true));
      final text = tester.widget<Text>(find.text('Read'));
      expect(
        (text.style ?? const TextStyle()).decoration,
        TextDecoration.lineThrough,
      );
    });

    testWidgets('no strikethrough when not done', (tester) async {
      await pumpTile(tester, state: loadedState(done: false));
      final text = tester.widget<Text>(find.text('Read'));
      final decoration = (text.style ?? const TextStyle()).decoration;
      expect(decoration, isNot(TextDecoration.lineThrough));
    });
  });

  // ── Interaction ───────────────────────────────────────────────────────────

  group('HabitTile interaction', () {
    testWidgets('calls toggleCompletion on checkbox tap', (tester) async {
      when(() => cubit.toggleCompletion(any())).thenAnswer((_) async {});
      await pumpTile(tester, state: loadedState());

      // The checkbox is the GestureDetector wrapping _AnimatedCheckbox
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pump(const Duration(milliseconds: 250)); // animation settles

      verify(() => cubit.toggleCompletion('habit-1')).called(1);
    });

    testWidgets('shows options sheet on long press', (tester) async {
      await pumpTile(tester, state: loadedState());

      await tester.longPress(find.byType(HabitTile));
      await tester.pumpAndSettle();

      expect(find.text('Archive habit'), findsOneWidget);
      expect(find.text('Delete habit'), findsOneWidget);
    });

    testWidgets('calls deleteHabit when Delete tapped in options',
        (tester) async {
      when(() => cubit.deleteHabit(any())).thenAnswer((_) async {});
      await pumpTile(tester, state: loadedState());

      await tester.longPress(find.byType(HabitTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete habit'));
      await tester.pumpAndSettle();

      verify(() => cubit.deleteHabit('habit-1')).called(1);
    });

    testWidgets('calls archiveHabit when Archive tapped in options',
        (tester) async {
      when(() => cubit.archiveHabit(any())).thenAnswer((_) async {});
      await pumpTile(tester, state: loadedState());

      await tester.longPress(find.byType(HabitTile));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Archive habit'));
      await tester.pumpAndSettle();

      verify(() => cubit.archiveHabit('habit-1')).called(1);
    });
  });
}
