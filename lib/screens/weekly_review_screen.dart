import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';

class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<TasksProvider>().tasks;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(weekStart.year, weekStart.month, weekStart.day);

    final completedThisWeek = tasks.where((t) {
      if (!t.completed || t.completedAt == null) return false;
      return t.completedAt!.isAfter(start);
    }).toList();

    final overdue = tasks.where((t) => t.isOverdue).toList();
    final pending = tasks.where((t) => !t.completed && !t.isSnoozed).toList();

    final byCategory = <String, int>{};
    for (final t in completedThisWeek) {
      final key = t.category ?? 'Uncategorized';
      byCategory[key] = (byCategory[key] ?? 0) + 1;
    }

    final df = DateFormat.MMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Weekly review')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Week of ${df.format(start)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _StatCard(
            title: 'Completed this week',
            value: '${completedThisWeek.length}',
            icon: Icons.check_circle_outline,
          ),
          const SizedBox(height: 8),
          _StatCard(
            title: 'Still pending',
            value: '${pending.length}',
            icon: Icons.pending_actions_outlined,
          ),
          const SizedBox(height: 8),
          _StatCard(
            title: 'Overdue',
            value: '${overdue.length}',
            icon: Icons.warning_amber_outlined,
          ),
          const SizedBox(height: 24),
          Text(
            'Completed by category',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          if (byCategory.isEmpty)
            const Text('No completed tasks this week yet.')
          else
            ...byCategory.entries.map(
              (e) => ListTile(
                dense: true,
                title: Text(e.key),
                trailing: Text('${e.value}'),
              ),
            ),
          const SizedBox(height: 24),
          Text(
            'Focus prompt',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            overdue.isNotEmpty
                ? 'You have ${overdue.length} overdue task(s). Clear those first.'
                : pending.isEmpty
                    ? 'Inbox zero — nice work. Plan next week’s top 3.'
                    : 'Pick 3 pending tasks as your main focus for the next few days.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (overdue.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Overdue list',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            ...overdue.map(
              (t) => ListTile(
                dense: true,
                title: Text(t.title),
                subtitle: t.deadline != null
                    ? Text(DateFormat.yMMMd().add_jm().format(t.deadline!))
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}