import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/hive_boxes.dart';
import 'core/notifications/notification_service.dart';
import 'features/habits/data/models/habit_model.dart';
import 'features/habits/data/models/habit_log_model.dart';
import 'features/habits/data/repositories/habit_repository.dart';
import 'features/habits/presentation/cubit/habit_cubit.dart';

import 'features/habits/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(HabitModelAdapter());
  Hive.registerAdapter(HabitFrequencyAdapter());
  Hive.registerAdapter(HabitLogModelAdapter());

  await Hive.openBox<HabitModel>(HiveBoxes.habits);
  await Hive.openBox<HabitLogModel>(HiveBoxes.habitLogs);

  // Initialize notifications BEFORE runApp
  await NotificationService.instance.initialize();

  runApp(const HabitTrackerApp());
}


class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HabitCubit(repository: HabitRepository())..loadHabits(),
      child: MaterialApp(
        title: 'Habit Tracker',
        debugShowCheckedModeBanner: false,
        home: const HomeScreen(),
      ),
    );
  }
}