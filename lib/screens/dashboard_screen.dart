import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_launcher.dart';
import '../navigator_key.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/tasks_provider.dart';
import '../services/notification_service.dart';
import '../widgets/reminder_dialog.dart';
import 'add_edit_task_screen.dart';
import 'login_screen.dart';
import 'settings_screen.dart';
import 'tasks_screen.dart';
import 'weekly_review_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  static const routeName = '/dashboard';

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    NotificationService.instance.onOpenReminder = _openReminderDialog;
    NotificationService.instance.onQuickAdd = _openQuickAdd;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<SettingsProvider>().requestAndroidReminderPermissions();
      if (!mounted) return;
      await context.read<TasksProvider>().syncOffline();
      if (!mounted) return;
      if (AppLauncher.openReminderOnColdStart) {
        AppLauncher.openReminderOnColdStart = false;
        await ReminderDialog.show(context);
      }
    });
  }

  @override
  void dispose() {
    if (NotificationService.instance.onOpenReminder == _openReminderDialog) {
      NotificationService.instance.onOpenReminder = null;
    }
    if (NotificationService.instance.onQuickAdd == _openQuickAdd) {
      NotificationService.instance.onQuickAdd = null;
    }
    super.dispose();
  }

  void _openReminderDialog() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null) {
      unawaited(ReminderDialog.show(ctx));
    }
  }

  void _openQuickAdd() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) return;
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(
        builder: (_) => const AddEditTaskScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    await Navigator.of(context).pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MyLifeManager')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Weekly review'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WeeklyReviewScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () async {
                Navigator.pop(context);
                await _logout();
              },
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Categories',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.checklist_outlined),
              title: const Text('Tasks'),
              subtitle: const Text('Active'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TasksScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.insights_outlined),
              title: const Text('Weekly review'),
              subtitle: const Text('Progress & focus'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WeeklyReviewScreen(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('Finance'),
              subtitle: const Text('Coming soon'),
              enabled: false,
            ),
          ),
        ],
      ),
    );
  }
}