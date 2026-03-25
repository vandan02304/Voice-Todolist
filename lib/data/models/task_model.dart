import 'package:hive/hive.dart';

part 'task_model.g.dart';

/// Core task data model.
@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  DateTime? dueDate;

  @HiveField(3)
  String status;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  bool isSynced;

  Task({
    required this.id,
    required this.title,
    this.dueDate,
    this.status = 'pending',
    required this.createdAt,
    this.isSynced = false,
  });

  factory Task.create({
    required String id,
    required String title,
    DateTime? dueDate,
  }) {
    return Task(
      id: id,
      title: title,
      dueDate: dueDate,
      status: 'pending',
      createdAt: DateTime.now(),
      isSynced: false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'title': title,
      'dueDate': dueDate?.toIso8601String(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'isSynced': true, // When written online, it's synced
    };
  }

  factory Task.fromFirestore(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      title: map['title'] as String,
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      status: map['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] as String),
      isSynced: true, // If it comes from Firestore, it's synced
    );
  }

  Task copyWith({
    String? title,
    DateTime? dueDate,
    String? status,
    bool? isSynced,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      status: status ?? this.status,
      createdAt: createdAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
