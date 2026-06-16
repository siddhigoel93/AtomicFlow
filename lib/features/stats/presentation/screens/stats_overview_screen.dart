import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../habits/presentation/cubit/habit_cubit.dart';
import '../../../habits/presentation/cubit/habit_state.dart';
import '../../../habits/data/models/habit_model.dart';
import '../../../habits/presentation/widgets/bottom_nav.dart';

class StatsOverviewScreen extends StatelessWidget {
  const StatsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Statistics', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20)),
        centerTitle: false,
      ),
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          if (state is HabitLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is! HabitLoaded) {
            return const Center(child: Text('No stats available'));
          }

          final habits = state.habits;
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'No stats yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create and complete habits to see stats',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Summary card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _SummaryStat(
                      label: 'Total Habits',
                      value: '${habits.length}',
                      icon: Icons.list_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _SummaryStat(
                      label: 'Active Streaks',
                      value: '${state.streaks.values.where((s) => s > 0).length}',
                      icon: Icons.local_fire_department,
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Select a habit to view detailed stats',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              ...habits.map((habit) {
                final streak = state.streaks[habit.id] ?? 0;
                final habitColor = Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  color: Theme.of(context).cardColor,
                  child: ListTile(
                    onTap: () => context.push('/stats/${habit.id}'),
                    leading: CircleAvatar(
                      backgroundColor: habitColor.withOpacity(0.1),
                      child: Icon(Icons.bar_chart, color: habitColor),
                    ),
                    title: Text(
                      habit.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      habit.frequency == HabitFrequency.daily ? 'Daily' : 'Weekly',
                    ),
                    trailing: streak > 0
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '$streak',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                );
              }),
            ],
          );
        },
      ),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: 1),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
