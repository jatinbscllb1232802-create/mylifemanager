import 'package:workmanager/workmanager.dart';

import '../background/workmanager_callback.dart';

class ReminderScheduler {
  ReminderScheduler._();

  static const String _periodicUnique = 'mlm_periodic_reminder';
  static const String _oneOffUnique = 'mlm_oneoff_reminder';

  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_periodicUnique);
    await Workmanager().cancelByUniqueName(_oneOffUnique);
  }

  static Future<void> scheduleEveryMinutes(int minutes) async {
    await Workmanager().cancelByUniqueName(_periodicUnique);
    if (minutes <= 0) return;

    final frequency = Duration(minutes: minutes < 15 ? 15 : minutes);

    await Workmanager().registerPeriodicTask(
      _periodicUnique,
      kReminderTask,
      frequency: frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
  }

  static Future<bool> scheduleTestInOneMinute() async {
    try {
      await Workmanager().cancelByUniqueName(_oneOffUnique);
      await Workmanager().registerOneOffTask(
        _oneOffUnique,
        kReminderOneOff,
        initialDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}