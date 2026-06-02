import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/hive_boxes.dart';
import 'features/habits/data/models/habit_model.dart';

void main()  async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(HabitModelAdapter());

  await Hive.openBox<HabitModel>(HiveBoxes.habits);
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Habit Tracker'),
      ),
    );
  }
}