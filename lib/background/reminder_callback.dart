import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../firebase_options.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';

@pragma('vm:entry-point')
Future<void> reminderAlarmCallback(int id) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        if (!e.toString().contains('duplicate-app')) {
          // continue anyway and try to show a notification
        }
      }
    }

    await NotificationService.instance.ensureInitializedForBackgroundIsolate();

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(StorageKeys.currentUid);

    // Always show something so we know the alarm fired
    if (uid == null) {
      await NotificationService.instance.showReminder(
        [],
        completedToday: 0,
      );
      return;
    }

    final taskService = TaskService();
    final pending = await taskService.fetchPendingTasks(uid);
    final completedToday = await taskService.countCompletedToday(uid);

    await NotificationService.instance.showReminder(
      pending,
      completedToday: completedToday,
    );
  } catch (e) {
    // Last-resort: try to show any notification so alarm is visible
    try {
      await NotificationService.instance.ensureInitializedForBackgroundIsolate();
      await NotificationService.instance.showReminder([]);
    } catch (_) {}
  }
}