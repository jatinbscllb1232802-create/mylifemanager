import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../screens/add_edit_task_screen.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final tasks = context.read<TasksProvider>();
    final df = DateFormat.yMMMd().add_jm();

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          Icons.delete_outline,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete task?'),
            content: Text('Remove "${task.title}" permanently?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        return ok ?? false;
      },
      onDismissed: (_) async {
        await tasks.deleteTask(task.id);
      },
      child: CheckboxListTile(
        value: task.completed,
        onChanged: (v) => tasks.setCompleted(task.id, v ?? false),
        title: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.completed ? TextDecoration.lineThrough : TextDecoration.none,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.category != null)
              Text(
                task.category!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            if (task.deadline != null)
              Text(
                'Due ${df.format(task.deadline!)}'
                '${task.isOverdue ? ' · Overdue' : ''}'
                '${task.isSnoozed ? ' · Snoozed' : ''}',
              ),
          ],
        ),
        isThreeLine: task.deadline != null && task.category != null,
        secondary: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                await Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => AddEditTaskScreen(task: task),
                  ),
                );
              case 'snooze':
                await tasks.snoozeUntilTomorrow(task.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Snoozed until tomorrow 9:00 AM'),
                    ),
                  );
                }
              case 'delete':
                await tasks.deleteTask(task.id);
            }
          },
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            if (!task.completed)
              const PopupMenuItem(
                value: 'snooze',
                child: Text('Done for today (snooze)'),
              ),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}