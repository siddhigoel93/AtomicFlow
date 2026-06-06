class NotificationChannels {
  // Android channel IDs — permanent, never rename after release
  static const String habitReminderId = 'habit_reminders';
  static const String habitReminderName = 'Habit Reminders';
  static const String habitReminderDesc =
      'Daily reminders to complete your habits';

  // Notification ID strategy:
  // Each habit gets a unique int ID derived from its string id.
  // We use hashCode & 0x7FFFFFFF to keep it positive and within int range.
  static int idForHabit(String habitId) => habitId.hashCode & 0x7FFFFFFF;
}
