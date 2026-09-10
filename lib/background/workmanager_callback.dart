import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/storage_keys.dart';
import '../firebase_options.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';

const String kReminderTask = 'reminder_task';
const String kReminderOneOff = 'reminder_oneoff';

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      if (Firebase.apps.isEmpty) {
        try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
        } catch (e) {
          if (!e.toString().contains('duplicate-app')) {
            // continue; we still try to notify
          }
        }
      }

      await NotificationService.instance.ensureInitializedForBackgroundIsolate();

      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(StorageKeys.currentUid);

      if (uid == null) {
        await NotificationService.instance.showReminder([]);
        return true;
      }

      final taskService = TaskService();
      final pending = await taskService.fetchPendingTasks(uid);
      final completedToday = await taskService.countCompletedToday(uid);

      await NotificationService.instance.showReminder(
        pending,
        completedToday: completedToday,
      );
    } catch (_) {
      try {
        await NotificationService.instance.ensureInitializedForBackgroundIsolate();
        await NotificationService.instance.showReminder([]);
      } catch (_) {}
    }

    return true;
  });
}