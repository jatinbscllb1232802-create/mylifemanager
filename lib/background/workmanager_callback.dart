import 'dart:ui';

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
    DartPluginRegistrant.ensureInitialized();
    WidgetsFlutterBinding.ensureInitialized();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      await NotificationService.instance
          .ensureInitializedForBackgroundIsolate();

      final prefs = await SharedPreferences.getInstance();
      final uid = prefs.getString(StorageKeys.currentUid);

      // A signed-out device has no work to perform. The foreground auth
      // provider cancels the scheduled work when the user signs out.
      if (uid == null || uid.isEmpty) {
        return true;
      }

      final taskService = TaskService();
      final pending = await taskService.fetchPendingTasks(uid);
      final completedToday = await taskService.countCompletedToday(uid);

      await NotificationService.instance.showReminder(
        pending,
        completedToday: completedToday,
      );

      return true;
    } catch (_) {
      // Returning false tells WorkManager the task failed and allows its
      // retry policy to handle a transient Firebase/notification failure.
      return false;
    }
  });
}
