import 'package:flutter/material.dart';
import '../../data/models/habit_model.dart';
import '../widgets/habit_tile.dart';
import '../widgets/add_habit_sheet.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mockHabits = [
      HabitModel(
        id: '1',
        name: 'Drink Water',
        iconCode: Icons.water_drop.codePoint,
        colorHex: '#378ADD',
        frequency: HabitFrequency.daily,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.now(),
      ),
      HabitModel(
        id: '2',
        name: 'Read Book',
        iconCode: Icons.menu_book.codePoint,
        colorHex: '#7F77DD',
        frequency: HabitFrequency.daily,
        weekdays: const [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.now(),
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Today', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: mockHabits.length,
        itemBuilder: (context, i) {
          return HabitTile(habit: mockHabits[i]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddHabitSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
