import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:habit_tracker/features/habits/data/models/habit_model.dart';
import 'package:habit_tracker/features/habits/presentation/cubit/habit_cubit.dart';
import 'package:habit_tracker/features/habits/presentation/cubit/habit_state.dart';
import 'package:habit_tracker/features/habits/presentation/widgets/add_habit_sheet.dart';

import '../../../helpers/mock_habit_repository.dart';
import '../../../helpers/test_helpers.dart';

class MockHabitCubit extends MockCubit<HabitState> implements HabitCubit {}

void main() {
  late MockHabitCubit cubit;

  setUpAll(registerFallbacks);

  setUp(() {
    cubit = MockHabitCubit();
    when(() => cubit.state).thenReturn(const HabitInitial());
  });

  // Pump AddHabitSheet inside a BottomSheet so it behaves like production
  Future<void> pumpSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<HabitCubit>.value(
          value: cubit,
          child: const Scaffold(body: AddHabitSheet()),
        ),
      ),
    );
    await tester.pump(); // settle initial frame
  }

  // ── Rendering ─────────────────────────────────────────────────────────────

  group('AddHabitSheet rendering', () {
    testWidgets('renders name field, icon picker, and save button',
        (tester) async {
      await pumpSheet(tester);

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.text('Add habit'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
    });

    testWidgets('does not show weekday picker for daily frequency',
        (tester) async {
      await pumpSheet(tester);
      // Weekday row only appears when Weekly is selected
      expect(find.text('M'), findsNothing);
    });

    testWidgets('shows weekday picker after tapping Weekly', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Weekly'));
      await tester.pump();

      // _WeekdayPicker shows M T W T F S S
      expect(find.text('M'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('shows no reminder set by default', (tester) async {
      await pumpSheet(tester);
      expect(find.text('No reminder set'), findsOneWidget);
    });
  });

  // ── Name validation ───────────────────────────────────────────────────────

  group('Name field validation', () {
    testWidgets('shows error when submitted empty', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Add habit'));
      await tester.pump();

      expect(find.text('Please enter a habit name'), findsOneWidget);
      verifyNever(() => cubit.addHabit(any()));
    });

    testWidgets('shows error when name is only whitespace', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), '   ');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      expect(find.text('Please enter a habit name'), findsOneWidget);
    });

    testWidgets('shows error when name is one character', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'A');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      expect(find.text('Name must be at least 2 characters'), findsOneWidget);
    });

    testWidgets('shows error when name exceeds 50 characters', (tester) async {
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'A' * 51);
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      expect(find.text('Name must be 50 characters or fewer'), findsOneWidget);
    });

    testWidgets('accepts name of exactly 2 characters', (tester) async {
      when(() => cubit.addHabit(any())).thenAnswer((_) async {});
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'Go');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      expect(find.text('Name must be at least 2 characters'), findsNothing);
      verify(() => cubit.addHabit(any())).called(1);
    });

    testWidgets('accepts name of exactly 50 characters', (tester) async {
      when(() => cubit.addHabit(any())).thenAnswer((_) async {});
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'A' * 50);
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      expect(find.text('Name must be 50 characters or fewer'), findsNothing);
      verify(() => cubit.addHabit(any())).called(1);
    });

    testWidgets('clears validation error after correcting input',
        (tester) async {
      await pumpSheet(tester);

      // Trigger error
      await tester.tap(find.text('Add habit'));
      await tester.pump();
      expect(find.text('Please enter a habit name'), findsOneWidget);

      // Fix the input
      when(() => cubit.addHabit(any())).thenAnswer((_) async {});
      await tester.enterText(find.byType(TextFormField), 'Read');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      expect(find.text('Please enter a habit name'), findsNothing);
    });
  });

  // ── Cubit interaction ────────────────────────────────────────────────────

  group('Cubit interaction', () {
    testWidgets('calls addHabit with correct name when valid', (tester) async {
      when(() => cubit.addHabit(any())).thenAnswer((_) async {});
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'Morning run');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      final captured =
          verify(() => cubit.addHabit(captureAny())).captured.single
              as HabitModel;
      expect(captured.name, 'Morning run');
    });

    testWidgets('sets daily frequency by default', (tester) async {
      when(() => cubit.addHabit(any())).thenAnswer((_) async {});
      await pumpSheet(tester);

      await tester.enterText(find.byType(TextFormField), 'Read');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      final captured =
          verify(() => cubit.addHabit(captureAny())).captured.single
              as HabitModel;
      expect(captured.frequency, HabitFrequency.daily);
      expect(captured.weekdays, isEmpty);
    });

    testWidgets('sets weekly frequency and weekdays when Weekly selected',
        (tester) async {
      when(() => cubit.addHabit(any())).thenAnswer((_) async {});
      await pumpSheet(tester);

      await tester.tap(find.text('Weekly'));
      await tester.pump();

      await tester.enterText(find.byType(TextFormField), 'Gym');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      final captured =
          verify(() => cubit.addHabit(captureAny())).captured.single
              as HabitModel;
      expect(captured.frequency, HabitFrequency.weekly);
      expect(captured.weekdays, isNotEmpty);
    });

    testWidgets('does not call addHabit when name is invalid', (tester) async {
      await pumpSheet(tester);

      await tester.tap(find.text('Add habit'));
      await tester.pump();

      verifyNever(() => cubit.addHabit(any()));
    });

    testWidgets('passes reminderTime as HH:mm string when set',
        (tester) async {
      when(() => cubit.addHabit(any())).thenAnswer((_) async {});
      await pumpSheet(tester);

      // Tap Set reminder — this opens TimePicker
      await tester.tap(find.text('Set reminder'));
      await tester.pumpAndSettle();

      // Confirm the picker (accept whatever default time it shows)
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), 'Meditate');
      await tester.tap(find.text('Add habit'));
      await tester.pump();

      final captured =
          verify(() => cubit.addHabit(captureAny())).captured.single
              as HabitModel;
      // reminderTime should be non-null and in HH:mm format
      expect(captured.reminderTime, isNotNull);
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(captured.reminderTime!), isTrue);
    });
  });
}
