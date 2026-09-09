import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import 'task_service.dart';

enum OfflineOpType { add, complete, snooze, delete }

class OfflineOp {
  OfflineOp({
    required this.type,
    required this.payload,
  });

  final OfflineOpType type;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'payload': payload,
      };

  factory OfflineOp.fromJson(Map<String, dynamic> json) {
    return OfflineOp(
      type: OfflineOpType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => OfflineOpType.add,
      ),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
    );
  }
}

class OfflineQueueService {
  OfflineQueueService({TaskService? taskService})
      : _taskService = taskService ?? TaskService();

  final TaskService _taskService;

  Future<bool> get isOnline async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<List<OfflineOp>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.offlineQueue);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => OfflineOp.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _save(List<OfflineOp> ops) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      StorageKeys.offlineQueue,
      jsonEncode(ops.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> enqueue(OfflineOp op) async {
    final ops = await _load();
    ops.add(op);
    await _save(ops);
  }

  Future<int> pendingCount() async => (await _load()).length;

  Future<void> flush(String uid) async {
    if (!await isOnline) return;
    final ops = await _load();
    if (ops.isEmpty) return;

    final remaining = <OfflineOp>[];
    for (final op in ops) {
      try {
        switch (op.type) {
          case OfflineOpType.add:
            await _taskService.addTask(
              uid: uid,
              title: op.payload['title'] as String,
              deadline: op.payload['deadline'] != null
                  ? DateTime.tryParse(op.payload['deadline'] as String)
                  : null,
              category: op.payload['category'] as String?,
            );
          case OfflineOpType.complete:
            await _taskService.setCompleted(
              uid: uid,
              taskId: op.payload['taskId'] as String,
              completed: op.payload['completed'] as bool? ?? true,
            );
          case OfflineOpType.snooze:
            await _taskService.snoozeUntilTomorrow(
              uid: uid,
              taskId: op.payload['taskId'] as String,
            );
          case OfflineOpType.delete:
            await _taskService.deleteTask(
              uid: uid,
              taskId: op.payload['taskId'] as String,
            );
        }
      } catch (_) {
        remaining.add(op);
      }
    }
    await _save(remaining);
  }
}