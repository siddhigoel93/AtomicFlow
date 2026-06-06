import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/notifications/notification_service.dart';
import '../cubit/habit_cubit.dart';
import '../cubit/habit_state.dart';
import '../widgets/habit_tile.dart';
import '../widgets/add_habit_sheet.dart';
import '../../data/models/habit_model.dart';

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

  @override
  Widget build(BuildContext context) {
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
      body: BlocBuilder<HabitCubit, HabitState>(
        builder: (context, state) {
          return switch (state) {
            HabitInitial() => const SizedBox.shrink(),
            HabitLoading() => const Center(child: CircularProgressIndicator()),
            HabitError(:final message) => _ErrorView(message: message),
            HabitLoaded(:final habits) when habits.isEmpty => const _EmptyState(),
            HabitLoaded(:final habits) => _HabitList(habits: habits),
          };
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddHabitSheet.show(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

void openAppSettings() {
  debugPrint('Open app settings clicked');
}

class _HabitList extends StatelessWidget {
  final List<HabitModel> habits;
  const _HabitList({required this.habits});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: habits.length,
      itemBuilder: (_, i) => HabitTile(habit: habits[i]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to create your first habit',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
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
