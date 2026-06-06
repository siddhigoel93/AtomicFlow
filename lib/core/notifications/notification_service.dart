import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../features/habits/data/models/habit_model.dart';
import 'notification_channels.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Initialization ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // Load ALL timezone data (ships with the timezone package)
    tz_data.initializeTimeZones();

    // Set local timezone — requires the flutter_timezone package OR
    // hardcode during development: tz.setLocalLocation(tz.getLocation('Asia/Kolkata'))
    // For production add flutter_timezone and call:
    //   final tzName = await FlutterTimezone.getLocalTimezone();
    //   tz.setLocalLocation(tz.getLocation(tzName));
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false, // we request manually below
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
      // Handles taps when app was terminated
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
    );

    await _createAndroidChannel();
    _initialized = true;
  }

  Future<void> _createAndroidChannel() async {
    if (!Platform.isAndroid) return;

    const channel = AndroidNotificationChannel(
      NotificationChannels.habitReminderId,
      NotificationChannels.habitReminderName,
      description: NotificationChannels.habitReminderDesc,
      importance: Importance.high,       // shows as heads-up notification
      enableVibration: true,
      playSound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // ── Permission request ────────────────────────────────────────────────────

  /// Call this once, e.g. on first app launch or before scheduling first habit.
  Future<bool> requestPermission() async {
    if (Platform.isIOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? false;
    }

    if (Platform.isAndroid) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      // Android 13+ (API 33) requires POST_NOTIFICATIONS permission
      final granted = await impl?.requestNotificationsPermission();
      return granted ?? false;
    }

    return false;
  }

  Future<bool> get hasPermission async {
    if (Platform.isAndroid) {
      final impl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await impl?.areNotificationsEnabled() ?? false;
    }
    // iOS: assume granted if we got this far (no sync check available)
    return true;
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  /// Schedules a daily repeating reminder for a habit.
  /// If the habit has no reminderTime, does nothing.
  Future<void> scheduleHabitReminder(HabitModel habit) async {
    if (habit.reminderTime == null) return;

    final notifId = NotificationChannels.idForHabit(habit.id);

    // Cancel any existing notification for this habit first
    await _plugin.cancel(notifId);

    final timeParts = habit.reminderTime!.split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);

    if (habit.frequency == HabitFrequency.daily) {
      await _scheduleDailyReminder(
        id: notifId,
        title: '🌟 ${habit.name}',
        body: "Time to work on your habit. Keep the streak alive!",
        hour: hour,
        minute: minute,
      );
    } else {
      // Weekly: schedule one notification per selected weekday
      // Each weekday gets a unique ID offset so they don't overwrite each other
      for (final weekday in habit.weekdays) {
        await _scheduleWeeklyReminder(
          id: notifId + weekday, // e.g. notifId+1 for Monday
          title: '🌟 ${habit.name}',
          body: "Today's the day — keep your streak going!",
          hour: hour,
          minute: minute,
          weekday: weekday, // 1=Mon, 7=Sun (DateTime convention)
        );
      }
    }
  }

  Future<void> _scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeats daily
    );
  }

  Future<void> _scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required int weekday,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfWeekdayTime(hour, minute, weekday),
      _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelHabitReminder(HabitModel habit) async {
    final notifId = NotificationChannels.idForHabit(habit.id);

    if (habit.frequency == HabitFrequency.daily) {
      await _plugin.cancel(notifId);
    } else {
      for (final weekday in habit.weekdays) {
        await _plugin.cancel(notifId + weekday);
      }
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  // ── Time helpers ──────────────────────────────────────────────────────────

  /// Returns the next occurrence of HH:mm in the device's local timezone.
  /// If that time has already passed today, returns tomorrow's instance.
  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    // If the time is in the past for today, push to tomorrow
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  /// Returns the next occurrence of a given weekday + HH:mm.
  tz.TZDateTime _nextInstanceOfWeekdayTime(
      int hour, int minute, int weekday) {
    var scheduled = _nextInstanceOfTime(hour, minute);

    // Advance day-by-day until we land on the right weekday
    while (scheduled.weekday != weekday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  // ── Notification details ──────────────────────────────────────────────────

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationChannels.habitReminderId,
        NotificationChannels.habitReminderName,
        channelDescription: NotificationChannels.habitReminderDesc,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        // Adds a 'Mark done' action button on the notification itself
        actions: [
          AndroidNotificationAction(
            'mark_done',
            'Mark done',
            cancelNotification: true,
          ),
        ],
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ── Tap handlers ──────────────────────────────────────────────────────────

  static void _onNotificationTapped(NotificationResponse response) {
    // Navigate to the habit — works when app is in foreground or background.
    // Use your GoRouter navigatorKey here:
    //   AppRouter.navigatorKey.currentContext?.go('/habit/${response.payload}')
    //
    // For now, just log:
    debugPrint('Notification tapped: payload=${response.payload}, '
        'action=${response.actionId}');

    // If user tapped 'Mark done' action button:
    if (response.actionId == 'mark_done' && response.payload != null) {
      // You can call the repository directly here since this runs outside
      // widget tree — no BuildContext available:
      //   HabitRepository().toggleCompletion(response.payload!, DateTime.now());
    }
  }

  // Top-level function (not a method) — required by flutter_local_notifications
  // for background tap handling. Must be defined outside any class or be static.
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('Background notification tapped: ${response.payload}');
  }
}
