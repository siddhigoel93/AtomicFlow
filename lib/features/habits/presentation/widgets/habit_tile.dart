// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/habit_cubit.dart';
import '../cubit/habit_state.dart';
import '../../data/models/habit_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../../../stats/presentation/cubit/stats_cubit.dart';
import '../../../stats/presentation/screens/stats_screen.dart';

class HabitTile extends StatelessWidget {
  final HabitModel habit;

  const HabitTile({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<HabitCubit, HabitState, ({bool done, int streak})>(
      selector: (state) => (
        done: state is HabitLoaded && state.isCompletedToday(habit.id),
        streak: state is HabitLoaded ? (state.streaks[habit.id] ?? 0) : 0,
      ),
      builder: (context, data) {
        return _HabitTileView(
          habit: habit,
          isDone: data.done,
          streak: data.streak,
          onTap: () => context.read<HabitCubit>().toggleCompletion(habit.id),
          onLongPress: () => _showOptions(context),
        );
      },
    );
  }

  void _showOptions(BuildContext context) {
    final cubit = context.read<HabitCubit>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('View statistics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => StatsCubit(repository: HabitRepository()),
                      child: StatsScreen(habitId: habit.id),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: const Text('Archive habit'),
              onTap: () {
                Navigator.pop(context);
                cubit.archiveHabit(habit.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete habit',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                cubit.deleteHabit(habit.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitTileView extends StatelessWidget {
  final HabitModel habit;
  final bool isDone;
  final int streak;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _HabitTileView({
    required this.habit,
    required this.isDone,
    required this.streak,
    required this.onTap,
    required this.onLongPress,
  });

  Color get _habitColor =>
      Color(int.parse(habit.colorHex.replaceFirst('#', '0xFF')));

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isDone
              ? _habitColor.withOpacity(0.12)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDone ? _habitColor.withOpacity(0.4) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ListTile(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => StatsCubit(repository: HabitRepository()),
                  child: StatsScreen(habitId: habit.id),
                ),
              ),
            );
          },
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: _HabitIcon(
            iconCode: habit.iconCode,
            color: _habitColor,
            isDone: isDone,
          ),
          title: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: isDone
                  ? Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .color!
                      .withOpacity(0.5)
                  : Theme.of(context).textTheme.bodyMedium!.color,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
            child: Text(habit.name),
          ),
          subtitle: streak > 0
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _StreakBadge(streak: streak, color: _habitColor),
                )
              : null,
          trailing: _AnimatedCheckbox(
            isDone: isDone,
            color: _habitColor,
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}

class _HabitIcon extends StatelessWidget {
  final int iconCode;
  final Color color;
  final bool isDone;

  const _HabitIcon({
    required this.iconCode,
    required this.color,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDone ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        IconData(iconCode, fontFamily: 'MaterialIcons'),
        color: color,
        size: 22,
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int streak;
  final Color color;

  const _StreakBadge({required this.streak, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.local_fire_department, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          '$streak day streak',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class _AnimatedCheckbox extends StatefulWidget {
  final bool isDone;
  final Color color;
  final VoidCallback onTap;

  const _AnimatedCheckbox({
    required this.isDone,
    required this.color,
    required this.onTap,
  });

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    widget.onTap();
    await _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: widget.isDone ? widget.color : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.isDone ? widget.color : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: widget.isDone
                ? const Icon(Icons.check, size: 16, color: Colors.white,
                    key: ValueKey('check'))
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
        ),
      ),
    );
  }
}
