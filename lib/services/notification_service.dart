import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/reminder_payloads.dart';
import '../constants/storage_keys.dart';
import '../firebase_options.dart';
import '../models/task.dart';

final FlutterLocalNotificationsPlugin _plugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> notificationTapBackground(NotificationResponse response) async {
  await NotificationService.handleBackgroundResponse(response);
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const AndroidNotificationChannel _channel =
      AndroidNotificationChannel(
    'task_reminders_v1',
    'Task reminders',
    description: 'Periodic reminders with pending tasks',
    importance: Importance.high,
  );

  static const int _notificationId = 71234;
  static const String _taskActionPrefix = 'task_done_';

  /// Called when user taps the reminder notification body (foreground).
  void Function()? onOpenReminder;

  Future<void> init() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onForegroundResponse,
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground,
    );

    await _ensureAndroidChannel();
  }

  /// Alarm callbacks run in a separate isolate; the plugin must be
  /// initialized there too.
  Future<void> ensureInitializedForBackgroundIsolate() async {
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
      ),
      onDidReceiveBackgroundNotificationResponse:
          notificationTapBackground,
    );

    await _ensureAndroidChannel();
  }

  Future<void> _ensureAndroidChannel() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await android?.createNotificationChannel(_channel);
  }

  Future<NotificationAppLaunchDetails?> getLaunchDetails() {
    return _plugin.getNotificationAppLaunchDetails();
  }

  void _onForegroundResponse(NotificationResponse response) {
    handleNotificationResponse(
      response,
      fromForeground: true,
    );
  }

  static Future<void> handleBackgroundResponse(
    NotificationResponse response,
  ) async {
    await handleNotificationResponse(
      response,
      fromForeground: false,
    );
  }

  static Future<void> handleNotificationResponse(
    NotificationResponse response, {
    required bool fromForeground,
  }) async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(StorageKeys.currentUid);

    if (uid == null) return;

    final actionId = response.actionId;

    if (actionId != null &&
        actionId.startsWith(_taskActionPrefix)) {
      final taskId = actionId.substring(
        _taskActionPrefix.length,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('tasks')
          .doc(taskId)
          .update({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return;
    }

    final bodyTap =
        response.actionId == null &&
        (response.payload == ReminderPayloads.openReminder ||
            response.notificationResponseType ==
                NotificationResponseType.selectedNotification);

    if (bodyTap && fromForeground) {
      NotificationService.instance.onOpenReminder?.call();
    }
  }

  Future<void> showReminder(List<Task> pending) async {
    if (pending.isEmpty) {
      final android = AndroidNotificationDetails(
        _channel.id,
        _channel.name,
        channelDescription: _channel.description,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      await _plugin.show(
        _notificationId,
        'MyLifeManager',
        'No pending tasks.',
        NotificationDetails(
          android: android,
        ),
      );

      return;
    }

    final lines = pending
        .map((t) => '• ${t.title}')
        .join('\n');

    final actions = <AndroidNotificationAction>[];

    for (var i = 0; i < pending.length && i < 3; i++) {
      final t = pending[i];

      final label = _shorten(
        'Done: ${t.title}',
        28,
      );

      actions.add(
        AndroidNotificationAction(
          '$_taskActionPrefix${t.id}',
          label,
          showsUserInterface: true,
          cancelNotification: true,
        ),
      );
    }

    final android = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(lines),
      actions: actions,
      category: AndroidNotificationCategory.reminder,
    );

    await _plugin.show(
      _notificationId,
      '${pending.length} pending task(s)',
      'Tap to review all tasks',
      NotificationDetails(
        android: android,
      ),
      payload: ReminderPayloads.openReminder,
    );
  }

  static String _shorten(
    String text,
    int maxChars,
  ) {
    if (text.length <= maxChars) {
      return text;
    }

    return '${text.substring(0, maxChars - 1)}…';
  }
}