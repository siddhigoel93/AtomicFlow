import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../features/habits/presentation/screens/home_screen.dart';
import '../features/stats/presentation/screens/stats_screen.dart';
import '../features/stats/presentation/screens/stats_overview_screen.dart';
import '../features/history/presentation/screens/history_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/stats/presentation/cubit/stats_cubit.dart';
import '../features/habits/data/repositories/habit_repository.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsOverviewScreen(),
    ),
    GoRoute(
      path: '/stats/:habitId',
      builder: (context, state) {
        final habitId = state.pathParameters['habitId']!;
        return BlocProvider(
          create: (_) => StatsCubit(repository: HabitRepository()),
          child: StatsScreen(habitId: habitId),
        );
      },
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
