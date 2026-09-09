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

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) rethrow;
    }
  }

  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString(StorageKeys.currentUid);
  if (uid == null) return;

  final taskService = TaskService();
  final pending = await taskService.fetchPendingTasks(uid);
  final completedToday = await taskService.countCompletedToday(uid);

  await NotificationService.instance.ensureInitializedForBackgroundIsolate();
  await NotificationService.instance.showReminder(
    pending,
    completedToday: completedToday,
  );
}