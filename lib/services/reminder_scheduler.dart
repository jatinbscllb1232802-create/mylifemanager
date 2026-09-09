import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

import '../background/reminder_callback.dart';

/// Registers the periodic alarm used for reminders.
class ReminderScheduler {
  ReminderScheduler._();

  static const int alarmId = 90001;
  static const int testAlarmId = 90002;

  static Future<void> cancel() async {
    await AndroidAlarmManager.cancel(alarmId);
  }

  static Future<void> scheduleEveryMinutes(int minutes) async {
    await cancel();
    if (minutes <= 0) return;

    final ok = await AndroidAlarmManager.periodic(
      Duration(minutes: minutes),
      alarmId,
      reminderAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
    // ignore: avoid_print
    print('ReminderScheduler: periodic($minutes min) scheduled=$ok');
  }

  /// Fires one reminder ~1 minute from now (for testing).
  static Future<void> scheduleTestInOneMinute() async {
    await AndroidAlarmManager.cancel(testAlarmId);
    final ok = await AndroidAlarmManager.oneShot(
      const Duration(minutes: 1),
      testAlarmId,
      reminderAlarmCallback,
      exact: true,
      wakeup: true,
      allowWhileIdle: true,
    );
    // ignore: avoid_print
    print('ReminderScheduler: test oneShot scheduled=$ok');
  }
}