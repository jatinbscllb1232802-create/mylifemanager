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

  /// Android periodic minimum is 15 minutes.
  static Future<void> scheduleEveryMinutes(int minutes) async {
    await Workmanager().cancelByUniqueName(_periodicUnique);
    if (minutes <= 0) return;

    final frequency = Duration(minutes: minutes < 15 ? 15 : minutes);

    await Workmanager().registerPeriodicTask(
      _periodicUnique,
      kReminderTask,
      frequency: frequency,
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  /// One-off test (~1 minute). Does not require 15-min minimum.
  static Future<bool> scheduleTestInOneMinute() async {
    try {
      await Workmanager().cancelByUniqueName(_oneOffUnique);
      await Workmanager().registerOneOffTask(
        _oneOffUnique,
        kReminderOneOff,
        initialDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}