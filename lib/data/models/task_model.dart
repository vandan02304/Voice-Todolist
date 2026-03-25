// GENERATED CODE - DO NOT MODIFY BY HAND
// Run: flutter pub run build_runner build

import 'package:hive/hive.dart';

part 'task_model.g.dart';

/// Represents the priority level of a task.
@HiveType(typeId: 1)
enum TaskPriority {
  @HiveField(0)
  low,
  @HiveField(1)
  medium,
  @HiveField(2)
  high,
}

/// Core task data model, stored locally in Hive and synced to Firestore.
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  DateTime updatedAt;

  @HiveField(6)
  TaskPriority priority;

  @HiveField(7)
  String? note;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.priority = TaskPriority.medium,
    this.note,
  });

  /// Create a new Task (convenience factory).
  factory Task.create({
    required String id,
    required String title,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? note,
  }) {
    final now = DateTime.now();
    return Task(
      id: id,
      title: title,
      isCompleted: false,
      dueDate: dueDate,
      createdAt: now,
      updatedAt: now,
      priority: priority,
      note: note,
    );
  }

  /// Convert to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'priority': priority.index,
      'note': note,
    };
  }

  /// Construct a Task from a Firestore document map.
  factory Task.fromFirestore(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      isCompleted: map['isCompleted'] as bool? ?? false,
      dueDate: map['dueDate'] != null
          ? DateTime.parse(map['dueDate'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      priority: TaskPriority.values[map['priority'] as int? ?? 1],
      note: map['note'] as String?,
    );
  }

  /// Returns a copy with updated fields.
  Task copyWith({
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? updatedAt,
    TaskPriority? priority,
    String? note,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      priority: priority ?? this.priority,
      note: note ?? this.note,
    );
  }

  @override
  String toString() =>
      'Task(id: $id, title: $title, isCompleted: $isCompleted, dueDate: $dueDate)';
}
