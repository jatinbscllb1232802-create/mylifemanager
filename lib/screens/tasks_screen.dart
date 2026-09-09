import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/tasks_provider.dart';
import '../widgets/task_tile.dart';
import 'add_edit_task_screen.dart';
import 'weekly_review_screen.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'Weekly review',
            icon: const Icon(Icons.insights_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const WeeklyReviewScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => const AddEditTaskScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<TasksProvider>(
        builder: (context, tasks, _) {
          final pending = tasks.filteredPending;
          final done = tasks.completedTasks;

          return Column(
            children: [
              // Filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                child: Row(
                  children: [
                    for (final f in TaskFilter.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_filterLabel(f)),
                          selected: tasks.filter == f,
                          onSelected: (_) => tasks.setFilter(f),
                        ),
                      ),
                  ],
                ),
              ),
              // Category filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All categories'),
                        selected: tasks.categoryFilter == null,
                        onSelected: (_) => tasks.setCategoryFilter(null),
                      ),
                    ),
                    for (final c in Task.categories)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: tasks.categoryFilter == c,
                          onSelected: (_) => tasks.setCategoryFilter(c),
                        ),
                      ),
                  ],
                ),
              ),
              if (tasks.completedTodayCount > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Completed today: ${tasks.completedTodayCount}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              Expanded(
                child: pending.isEmpty && done.isEmpty
                    ? const Center(
                        child: Text('No tasks yet. Tap + to add one.'),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 88),
                        children: [
                          if (pending.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Text(
                                'Pending (${pending.length})',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            ...pending.map((t) => TaskTile(task: t)),
                          ],
                          if (done.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: Text(
                                'Completed',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            ...done.map((t) => TaskTile(task: t)),
                          ],
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _filterLabel(TaskFilter f) {
    switch (f) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.today:
        return 'Today';
      case TaskFilter.overdue:
        return 'Overdue';
      case TaskFilter.noDeadline:
        return 'No deadline';
    }
  }
}