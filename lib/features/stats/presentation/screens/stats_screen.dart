// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../habits/presentation/cubit/habit_cubit.dart';
import '../../../habits/presentation/cubit/habit_state.dart';
import '../cubit/stats_cubit.dart';
import '../widgets/heatmap_widget.dart';
import '../widgets/completion_arc_widget.dart';

class StatsScreen extends StatelessWidget {
  final String habitId;

  const StatsScreen({super.key, required this.habitId});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HabitCubit, HabitState>(
      builder: (context, state) {
        if (state is! HabitLoaded) return const SizedBox.shrink();

        final habitIndex = state.habits.indexWhere((h) => h.id == habitId);
        if (habitIndex == -1) {
          return const Scaffold(
            body: Center(
              child: Text('Habit not found'),
            ),
          );
        }
        final habit = state.habits[habitIndex];
        final streak = state.streaks[habitId] ?? 0;
        final habitColor =
            Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));

        // Build the heatmap data from repository logs driven by StatsCubit
        final heatmapData = context.read<StatsCubit>().getHeatmapData(habitId);

        final completionRate = _computeWeeklyRate(heatmapData);

        return Scaffold(
          appBar: AppBar(
            title: Text(habit.name),
            centerTitle: false,
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Metric cards ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      label: 'Current streak',
                      value: '$streak',
                      unit: streak == 1 ? 'day' : 'days',
                      color: habitColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      label: 'This week',
                      value: '${(completionRate * 100).round()}',
                      unit: '%',
                      color: habitColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Completion arc ────────────────────────────────────────────
              Center(
                child: CompletionArcWidget(
                  completionRate: completionRate,
                  color: habitColor,
                  label: 'This week',
                  size: 140,
                ),
              ),
              const SizedBox(height: 32),

              // ── Heatmap ───────────────────────────────────────────────────
              Text(
                'Activity',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              HeatmapWidget(
                data: heatmapData,
                color: habitColor,
                weeks: 18,
              ),
            ],
          ),
        );
      },
    );
  }

  double _computeWeeklyRate(Map<DateTime, bool> data) {
    final today = DateTime.now();
    int done = 0;
    int total = 0;
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day - i);
      if (!d.isAfter(today)) {
        total++;
        if (data[d] == true) done++;
      }
    }
    return total == 0 ? 0 : done / total;
  }
}

// ── Metric card ───────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .color!
                  .withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .color!
                        .withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
