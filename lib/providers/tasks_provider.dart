import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/task.dart';
import '../services/offline_queue_service.dart';
import '../services/task_service.dart';
import 'auth_provider.dart';

enum TaskFilter { all, today, overdue, noDeadline }

class TasksProvider extends ChangeNotifier {
  TasksProvider({
    required TaskService taskService,
    required AuthProvider authProvider,
    OfflineQueueService? offlineQueue,
  })  : _taskService = taskService,
        _authProvider = authProvider,
        _offlineQueue = offlineQueue ?? OfflineQueueService() {
    _authProvider.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final TaskService _taskService;
  final AuthProvider _authProvider;
  final OfflineQueueService _offlineQueue;

  StreamSubscription<List<Task>>? _sub;
  List<Task> _tasks = [];
  TaskFilter _filter = TaskFilter.all;
  String? _categoryFilter;

  List<Task> get tasks => List.unmodifiable(_tasks);
  TaskFilter get filter => _filter;
  String? get categoryFilter => _categoryFilter;

  List<Task> get pendingTasks => _tasks
      .where((t) => !t.completed && !t.isSnoozed)
      .toList(growable: false);

  List<Task> get completedTasks =>
      _tasks.where((t) => t.completed).toList(growable: false);

  List<Task> get filteredPending {
    var list = pendingTasks;
    switch (_filter) {
      case TaskFilter.all:
        break;
      case TaskFilter.today:
        list = list.where((t) => t.isDueToday).toList();
      case TaskFilter.overdue:
        list = list.where((t) => t.isOverdue).toList();
      case TaskFilter.noDeadline:
        list = list.where((t) => t.deadline == null).toList();
    }
    if (_categoryFilter != null) {
      list = list.where((t) => t.category == _categoryFilter).toList();
    }
    return list;
  }

  int get completedTodayCount {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (!t.completed || t.completedAt == null) return false;
      final c = t.completedAt!;
      return c.year == now.year && c.month == now.month && c.day == now.day;
    }).length;
  }

  void setFilter(TaskFilter f) {
    _filter = f;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void _onAuthChanged() {
    _sub?.cancel();
    final uid = _authProvider.user?.uid;
    if (uid == null) {
      _tasks = [];
      notifyListeners();
      return;
    }
    unawaited(_offlineQueue.flush(uid));
    _sub = _taskService.watchTasks(uid).listen((list) {
      _tasks = list;
      notifyListeners();
    });
  }

  Future<void> addTask({
    required String title,
    DateTime? deadline,
    String? category,
  }) async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;

    if (await _offlineQueue.isOnline) {
      await _taskService.addTask(
        uid: uid,
        title: title,
        deadline: deadline,
        category: category,
      );
    } else {
      await _offlineQueue.enqueue(OfflineOp(
        type: OfflineOpType.add,
        payload: {
          'title': title,
          if (deadline != null) 'deadline': deadline.toIso8601String(),
          if (category != null) 'category': category,
        },
      ));
    }
  }

  Future<void> updateTask(Task task) async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;
    await _taskService.updateTask(uid: uid, task: task);
  }

  Future<void> setCompleted(String taskId, bool completed) async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;

    if (await _offlineQueue.isOnline) {
      await _taskService.setCompleted(
        uid: uid,
        taskId: taskId,
        completed: completed,
      );
    } else {
      await _offlineQueue.enqueue(OfflineOp(
        type: OfflineOpType.complete,
        payload: {'taskId': taskId, 'completed': completed},
      ));
    }
  }

  Future<void> snoozeUntilTomorrow(String taskId) async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;

    if (await _offlineQueue.isOnline) {
      await _taskService.snoozeUntilTomorrow(uid: uid, taskId: taskId);
    } else {
      await _offlineQueue.enqueue(OfflineOp(
        type: OfflineOpType.snooze,
        payload: {'taskId': taskId},
      ));
    }
  }

  Future<void> deleteTask(String taskId) async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;

    if (await _offlineQueue.isOnline) {
      await _taskService.deleteTask(uid: uid, taskId: taskId);
    } else {
      await _offlineQueue.enqueue(OfflineOp(
        type: OfflineOpType.delete,
        payload: {'taskId': taskId},
      ));
    }
  }

  Future<void> syncOffline() async {
    final uid = _authProvider.user?.uid;
    if (uid == null) return;
    await _offlineQueue.flush(uid);
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _sub?.cancel();
    super.dispose();
  }
}