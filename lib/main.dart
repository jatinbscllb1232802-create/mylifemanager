import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'app_launcher.dart';
import 'constants/reminder_payloads.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/tasks_provider.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/settings_service.dart';
import 'services/startup_diagnostics.dart';
import 'services/task_service.dart';
import 'services/update_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const StartupApp());
}

class StartupApp extends StatefulWidget {
  const StartupApp({super.key});

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  final StartupDiagnostics _diagnostics = StartupDiagnostics.instance;

  String _status = 'Starting MyLifeManager...';
  String? _error;
  List<String> _logs = <String>[];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _log(String message) async {
    await _diagnostics.log(message);

    if (!mounted) return;

    final logs = await _diagnostics.getLogs();

    if (!mounted) return;

    setState(() {
      _logs = logs;
    });
  }

  Future<T> _runStep<T>(
    String name,
    Future<T> Function() action,
  ) async {
    if (mounted) {
      setState(() {
        _status = '$name...';
      });
    }

    await _log('$name STARTED');

    try {
      final result = await action().timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          throw TimeoutException(
            '$name timed out after 20 seconds.',
          );
        },
      );

      await _log('$name COMPLETED');

      return result;
    } catch (e, stackTrace) {
      await _log('ERROR in $name: $e');
      await _log('STACK TRACE: $stackTrace');
      rethrow;
    }
  }

  Future<void> _initialize() async {
    try {
      await _diagnostics.clear();

      await _log('APPLICATION STARTED');

      await _runStep(
        'Flutter binding initialization',
        () async {},
      );

      await _runStep(
        'Firebase initialization',
        () async {
          try {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            );
          } catch (e) {
            // Ignore if the default app already exists (common on Android)
            if (e.toString().contains('duplicate-app')) {
              await _log('Firebase already initialized (duplicate-app ignored)');
            } else {
              rethrow;
            }
          }
        },
      );

      await _runStep(
        'NotificationService initialization',
        () async {
          await NotificationService.instance.init();
        },
      );

      await _runStep(
        'AndroidAlarmManager initialization',
        () async {
          await AndroidAlarmManager.initialize();
        },
      );

      final launchDetails = await _runStep(
        'Notification launch details',
        () async {
          return NotificationService.instance.getLaunchDetails();
        },
      );

      final payload =
          launchDetails?.notificationResponse?.payload;

      AppLauncher.openReminderOnColdStart =
          launchDetails?.didNotificationLaunchApp == true &&
          payload == ReminderPayloads.openReminder;

      await _log('REMINDER LAUNCH CHECK COMPLETED');

      if (!mounted) return;

      setState(() {
        _status = 'Starting application...';
        _ready = true;
      });

      await _log('STARTUP COMPLETED - BUILDING APP UI');
    } catch (e, stackTrace) {
      await _log('STARTUP FAILED: $e');
      await _log('FINAL STACK TRACE: $stackTrace');

      if (!mounted) return;

      final logs = await _diagnostics.getLogs();

      setState(() {
        _error = '$e';
        _logs = logs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'MyLifeManager startup failed',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Startup log:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        color: Colors.black12,
                        child: Text(
                          _logs.isEmpty
                              ? 'No logs recorded.'
                              : _logs.join('\n'),
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _initialize,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      _status,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return MultiProvider(
      providers: [
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => SettingsService()),
        Provider(create: (_) => TaskService()),
        Provider(create: (_) => UpdateService()),
        ChangeNotifierProvider(
          create: (ctx) => AuthProvider(
            authService: ctx.read<AuthService>(),
            settingsService: ctx.read<SettingsService>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => TasksProvider(
            taskService: ctx.read<TaskService>(),
            authProvider: ctx.read<AuthProvider>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) => SettingsProvider(
            settingsService: ctx.read<SettingsService>(),
            authProvider: ctx.read<AuthProvider>(),
          ),
        ),
      ],
      child: const MyLifeManagerApp(),
    );
  }
}

class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message);

  @override
  String toString() => message;
}