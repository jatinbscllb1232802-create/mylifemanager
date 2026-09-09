import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/task.dart';

class TaskService {
  TaskService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _tasksCol(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  Stream<List<Task>> watchTasks(String uid) {
    return _tasksCol(uid).snapshots().map((snap) {
      final list = snap.docs.map(Task.fromFirestore).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return list;
    });
  }

  Future<List<Task>> fetchPendingTasks(String uid) async {
    final snap =
        await _tasksCol(uid).where('completed', isEqualTo: false).get();
    final list = snap.docs.map(Task.fromFirestore).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    // Hide currently snoozed tasks from reminders
    return list.where((t) => !t.isSnoozed).toList();
  }

  Future<String> addTask({
    required String uid,
    required String title,
    DateTime? deadline,
    String? category,
  }) async {
    final now = DateTime.now();
    final doc = _tasksCol(uid).doc();
    await doc.set({
      'title': title.trim(),
      if (deadline != null) 'deadline': Timestamp.fromDate(deadline),
      if (category != null && category.isNotEmpty) 'category': category,
      'completed': false,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    });
    return doc.id;
  }

  Future<void> updateTask({
    required String uid,
    required Task task,
  }) async {
    await _tasksCol(uid).doc(task.id).set(task.toFirestore(), SetOptions(merge: true));
  }

  Future<void> setCompleted({
    required String uid,
    required String taskId,
    required bool completed,
  }) async {
    await _tasksCol(uid).doc(taskId).update({
      'completed': completed,
      'completedAt': completed ? FieldValue.serverTimestamp() : null,
      'snoozedUntil': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> snoozeUntilTomorrow({
    required String uid,
    required String taskId,
  }) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 9, 0);
    await _tasksCol(uid).doc(taskId).update({
      'snoozedUntil': Timestamp.fromDate(tomorrow),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteTask({
    required String uid,
    required String taskId,
  }) async {
    await _tasksCol(uid).doc(taskId).delete();
  }

  Future<int> countCompletedToday(String uid) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final snap = await _tasksCol(uid)
        .where('completed', isEqualTo: true)
        .where('completedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .get();
    return snap.docs.length;
  }
}