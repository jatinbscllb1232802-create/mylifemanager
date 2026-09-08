import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import '../firebase_options.dart';
import '../services/notification_service.dart';
import '../services/task_service.dart';

/// Called by [AndroidAlarmManager] on each interval (may be delayed by Doze).
///
/// TODO: If you need sub-15-minute intervals reliably, consider a foreground
/// service (persistent notification) — tradeoff: higher battery use.
@pragma('vm:entry-point')
Future<void> reminderAlarmCallback(int id) async {
  DartPluginRegistrant.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  final prefs = await SharedPreferences.getInstance();
  final uid = prefs.getString(StorageKeys.currentUid);
  if (uid == null) return;

  final tasks = await TaskService().fetchPendingTasks(uid);
  await NotificationService.instance.ensureInitializedForBackgroundIsolate();
  await NotificationService.instance.showReminder(tasks);
}