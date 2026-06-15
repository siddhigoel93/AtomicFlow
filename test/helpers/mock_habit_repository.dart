import 'package:mocktail/mocktail.dart';
import 'package:habit_tracker/features/habits/data/repositories/habit_repository.dart';
import 'package:habit_tracker/features/habits/data/models/habit_model.dart';

class MockHabitRepository extends Mock implements HabitRepository {}

/// Call in setUpAll() to register fallback values for any() matchers.
void registerFallbacks() {
  registerFallbackValue(
    HabitModel(
      id: 'fallback',
      name: 'fallback',
      iconCode: 0,
      colorHex: '#000000',
      frequency: HabitFrequency.daily,
      weekdays: [],
      createdAt: DateTime(2024),
    ),
  );
}
