import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  const Task({
    required this.id,
    required this.title,
    this.deadline,
    required this.completed,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.snoozedUntil,
  });

  final String id;
  final String title;
  final DateTime? deadline;
  final bool completed;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final DateTime? snoozedUntil;

  static const categories = ['Work', 'Personal', 'Calls', 'Admin'];

  bool get isSnoozed {
    if (snoozedUntil == null) return false;
    return snoozedUntil!.isAfter(DateTime.now());
  }

  bool get isOverdue {
    if (completed || deadline == null || isSnoozed) return false;
    return deadline!.isBefore(DateTime.now());
  }

  bool get isDueToday {
    if (completed || deadline == null || isSnoozed) return false;
    final now = DateTime.now();
    final d = deadline!;
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  factory Task.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Task(
      id: doc.id,
      title: d['title'] as String? ?? '',
      deadline: (d['deadline'] as Timestamp?)?.toDate(),
      completed: d['completed'] as bool? ?? false,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: d['category'] as String?,
      snoozedUntil: (d['snoozedUntil'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      if (deadline != null) 'deadline': Timestamp.fromDate(deadline!),
      'completed': completed,
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (category != null) 'category': category,
      if (snoozedUntil != null) 'snoozedUntil': Timestamp.fromDate(snoozedUntil!),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    bool? deadlineClear,
    bool? completed,
    DateTime? completedAt,
    bool? completedAtClear,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    bool? categoryClear,
    DateTime? snoozedUntil,
    bool? snoozedUntilClear,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadlineClear == true ? null : (deadline ?? this.deadline),
      completed: completed ?? this.completed,
      completedAt: completedAtClear == true
          ? null
          : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: categoryClear == true ? null : (category ?? this.category),
      snoozedUntil: snoozedUntilClear == true
          ? null
          : (snoozedUntil ?? this.snoozedUntil),
    );
  }
}