import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../../../core/notifications/notification_service.dart';
import '../../../stats/presentation/widgets/completion_arc_widget.dart';
import '../../data/models/habit_model.dart';
import '../../data/models/habit_log_model.dart';
import '../../data/repositories/habit_repository.dart';
import '../cubit/habit_cubit.dart';
import '../cubit/habit_state.dart';
import '../widgets/habit_tile.dart';
import '../widgets/add_habit_sheet.dart';
import '../widgets/bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable notifications in Settings for habit reminders'),
          action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
        ),
      );
    }
  }

  Map<DateTime, bool> _buildActivityMap(HabitState state) {
    if (state is! HabitLoaded) return {};
    final repository = HabitRepository();
    final today = DateTime.now();
    final activityMap = <DateTime, bool>{};
    for (int i = 0; i < 7; i++) {
      final date = today.subtract(Duration(days: 3 - i));
      final normalized = HabitLogModel.normalizeDate(date);
      final logs = repository.getLogsForDate(normalized);
      activityMap[normalized] = logs.isNotEmpty;
    }
    return activityMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const _GreetingHeader(),
        actions: [
          IconButton(icon: const Icon(Icons.search_outlined), onPressed: () {}),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) => switch (state) {
          HabitLoading() => const Center(child: CircularProgressIndicator()),
          HabitError(:final message) => _ErrorView(message: message),
          HabitLoaded(:final habits) => CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: WeekStripWidget(activityMap: _buildActivityMap(state)),
                )),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _StatsRow(state: state),
                )),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _ProgressArcCard(state: state),
                )),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                habits.isEmpty
                    ? const SliverToBoxAdapter(child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: _EmptyState(),
                      ))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: _HabitSliver(habits: habits, state: state),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                const SliverToBoxAdapter(child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                  child: _QuoteCard(),
                )),
              ],
            ),
          _ => const SizedBox.shrink(),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddHabitSheet.show(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

void openAppSettings() {
  debugPrint('Open app settings clicked');
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning 👋';
    if (hour < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_greeting, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        Text(
          DateFormat('EEEE, MMMM d').format(DateTime.now()),
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class WeekStripWidget extends StatelessWidget {
  final Map<DateTime, bool> activityMap; // date → has any completions

  const WeekStripWidget({super.key, required this.activityMap});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final date = today.subtract(Duration(days: 3 - i));
          final isToday = i == 3;
          final hasActivity = activityMap[HabitLogModel.normalizeDate(date)] ?? false;

          return Container(
            width: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('E').format(date).substring(0, 2),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 3),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                    color: isToday
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).textTheme.bodyMedium!.color,
                  ),
                ),
                if (hasActivity)
                  Container(
                    margin: const EdgeInsets.only(top: 3),
                    width: 5, height: 5,
                    decoration: const BoxDecoration(
                      color: Color(0xFF1D9E75),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final HabitLoaded state;

  const _StatsRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final doneToday = state.habits
        .where((h) => state.isCompletedToday(h.id)).length;
    final total = state.habits.length;
    final bestStreak = state.streaks.values.fold(0, math.max);
    final weeklyRate = _computeWeeklyRate(state);
    final remaining = total - doneToday;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            value: '🔥 $bestStreak',
            label: 'Best streak',
            sub: 'days',
            subColor: Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${doneToday}/${total}',
            label: 'Done today',
            sub: doneToday == total && total > 0 ? 'Perfect!' : '$remaining left',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            value: '${weeklyRate}%',
            label: 'This week',
            sub: 'rate',
            subColor: const Color(0xFF1D9E75),
          ),
        ),
      ],
    );
  }

  int _computeWeeklyRate(HabitLoaded state) {
    if (state.habits.isEmpty) return 0;
    
    final repository = HabitRepository();
    final today = DateTime.now();
    int done = 0;
    int totalCompletions = 0;
    
    for (int i = 6; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day - i);
      if (!d.isAfter(today)) {
        final logs = repository.getLogsForDate(d);
        final habitIds = state.habits.map((h) => h.id).toSet();
        done += logs.where((log) => habitIds.contains(log.habitId)).length;
        totalCompletions += state.habits.length;
      }
    }
    
    if (totalCompletions == 0) return 0;
    return ((done / totalCompletions) * 100).round();
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final String sub;
  final Color? subColor;

  const _StatCard({
    required this.value,
    required this.label,
    required this.sub,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
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
              fontSize: 11,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: subColor ?? Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressArcCard extends StatelessWidget {
  final HabitLoaded state;

  const _ProgressArcCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final doneToday = state.habits
        .where((h) => state.isCompletedToday(h.id)).length;
    final total = state.habits.length;
    final rate = total == 0 ? 0.0 : doneToday / total;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CompletionArcWidget(
            completionRate: rate,
            color: Theme.of(context).colorScheme.primary,
            label: 'Today',
            size: 72,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's progress",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  total == 0
                      ? 'Add habits to see progress.'
                      : doneToday == total
                          ? 'All habits done! Streak secured.'
                          : '$doneToday of $total habits complete.',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  static const _suggestions = [
    (icon: Icons.directions_run, name: 'Morning run', freq: 'Daily'),
    (icon: Icons.menu_book,      name: 'Read 20 pages', freq: 'Daily'),
    (icon: Icons.water_drop,     name: 'Drink water', freq: 'Daily'),
    (icon: Icons.self_improvement, name: 'Meditate', freq: 'Daily'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Empty state card
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(Icons.park_outlined, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              const Text('No habits yet',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(
                'Start small. Pick one thing to do every day.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => AddHabitSheet.show(context),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add first habit'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Suggested habits
        Align(
          alignment: Alignment.centerLeft,
          child: Text('Suggested habits',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500, letterSpacing: 0.5)),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _suggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final s = _suggestions[i];
              return GestureDetector(
                onTap: () {
                  // Pre-fill AddHabitSheet with this suggestion
                  AddHabitSheet.show(
                    context,
                    prefillName: s.name,
                    prefillIcon: s.icon,
                  );
                },
                child: Container(
                  width: 115,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(s.icon, size: 18, color: Colors.grey.shade600),
                      const SizedBox(height: 6),
                      Text(s.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      Text(s.freq,
                          style: TextStyle(fontSize: 11,
                              color: Colors.grey.shade400)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuoteCard extends StatelessWidget {
  static const _quotes = [
    (text: 'We are what we repeatedly do. Excellence, then, is not an act, but a habit.', author: 'Aristotle'),
    (text: 'Motivation gets you started. Habit keeps you going.', author: 'Jim Ryun'),
    (text: 'Small daily improvements over time lead to stunning results.', author: 'Robin Sharma'),
    (text: 'First forget inspiration. Habit is more dependable.', author: 'Octavia Butler'),
    (text: 'You do not rise to the level of your goals. You fall to the level of your systems.', author: 'James Clear'),
    (text: 'Chains of habit are too light to be felt until they are too heavy to be broken.', author: 'Warren Buffett'),
    (text: 'The secret of your future is hidden in your daily routine.', author: 'Mike Murdock'),
  ];

  const _QuoteCard();

  @override
  Widget build(BuildContext context) {
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    final q = _quotes[dayOfYear % _quotes.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded,
              color: Theme.of(context).colorScheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.text,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600,
                        height: 1.6)),
                const SizedBox(height: 6),
                Text('— ${q.author}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitSliver extends StatelessWidget {
  final List<HabitModel> habits;
  final HabitState state;

  const _HabitSliver({required this.habits, required this.state});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final habit = habits[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: HabitTile(habit: habit),
          );
        },
        childCount: habits.length,
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return const AppBottomNavBar(selectedIndex: 0);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => context.read<HabitCubit>().loadHabits(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
