import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../habits/data/repositories/habit_repository.dart';
import '../../../habits/data/models/habit_log_model.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../habits/presentation/cubit/habit_cubit.dart';
import '../../../habits/presentation/cubit/habit_state.dart';
import '../../../habits/presentation/widgets/bottom_nav.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = HabitRepository();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        centerTitle: false,
      ),
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          if (state is HabitLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! HabitLoaded) {
            return const Center(child: Text('No history available'));
          }

          // Fetch all logs from the repository and sort descending by date
          final allLogs = repository.getAllLogs()
              .where((log) => log.isCompleted)
              .toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (allLogs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Log completions to build your history',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          // Group logs by normalized date string
          final groupedLogs = <String, List<HabitLogModel>>{};
          final dateFormat = DateFormat('EEEE, MMMM d, yyyy');

          for (final log in allLogs) {
            final dateKey = dateFormat.format(log.date);
            groupedLogs.putIfAbsent(dateKey, () => []).add(log);
          }

          final keys = groupedLogs.keys.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final dateString = keys[index];
              final logs = groupedLogs[dateString]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 4.0),
                    child: Text(
                      dateString,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  ...logs.map((log) {
                    final habit = state.habits.firstWhere(
                      (h) => h.id == log.habitId,
                      orElse: () => HabitModel(
                        id: log.habitId,
                        name: 'Deleted Habit',
                        iconCode: Icons.help_outline.codePoint,
                        colorHex: '#888780',
                        frequency: HabitFrequency.daily,
                        weekdays: const [],
                        createdAt: DateTime.now(),
                      ),
                    );
                    final habitColor = Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8.0),
                      elevation: 0,
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: habitColor.withOpacity(0.1),
                          child: Icon(Icons.check, color: habitColor),
                        ),
                        title: Text(
                          habit.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Completed at ${DateFormat('jm').format(log.loggedAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            },
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 2),
    );
  }
}
