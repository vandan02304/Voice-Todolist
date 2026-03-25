import 'package:hive_flutter/hive_flutter.dart';
import '../models/task_model.dart';

/// Repository for CRUD operations on the local Hive task box.
class HiveTaskRepository {
  static const String _boxName = 'tasks';

  Box<Task>? _box;

  Box<Task> get box {
    assert(_box != null && _box!.isOpen, 'Hive task box is not open. Call init() first.');
    return _box!;
  }

  /// Opens the Hive box. Must be called once at app startup.
  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<Task>(_boxName);
    } else {
      _box = await Hive.openBox<Task>(_boxName);
    }
  }

  /// Returns all tasks sorted by creation date (newest first).
  List<Task> getAll() {
    final tasks = box.values.toList();
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  /// Returns a single task by ID, or null if not found.
  Task? getById(String id) {
    try {
      return box.values.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Saves (insert or update) a task.
  Future<void> save(Task task) async {
    await box.put(task.id, task);
  }

  /// Saves multiple tasks at once (used during sync).
  Future<void> saveAll(List<Task> tasks) async {
    final map = {for (final t in tasks) t.id: t};
    await box.putAll(map);
  }

  /// Deletes a task by ID.
  Future<void> delete(String id) async {
    await box.delete(id);
  }

  /// Marks a task as completed.
  Future<Task?> markComplete(String id) async {
    final task = getById(id);
    if (task == null) return null;
    final updated = task.copyWith(isCompleted: true, updatedAt: DateTime.now());
    await save(updated);
    return updated;
  }

  /// Marks a task as not completed.
  Future<Task?> markIncomplete(String id) async {
    final task = getById(id);
    if (task == null) return null;
    final updated = task.copyWith(isCompleted: false, updatedAt: DateTime.now());
    await save(updated);
    return updated;
  }

  /// Returns all incomplete tasks that are overdue.
  List<Task> getOverdue() {
    final now = DateTime.now();
    return box.values
        .where((t) => !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now))
        .toList();
  }

  /// Clears all tasks (used during full sync reset).
  Future<void> clearAll() async {
    await box.clear();
  }
}
