import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../data/models/task_model.dart';
import '../data/repositories/firestore_task_repository.dart';
import '../data/repositories/hive_task_repository.dart';
import '../data/repositories/offline_queue_repository.dart';
import 'sync_provider.dart';

const _uuid = Uuid();

/// State for the task list.
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;

  const TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
  }) =>
      TaskState(
        tasks: tasks ?? this.tasks,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  List<Task> get incomplete => tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completed  => tasks.where((t) =>  t.isCompleted).toList();
}

/// Central task notifier: CRUD, Hive local storage, Firestore sync, offline queue.
class TaskNotifier extends Notifier<TaskState> {
  final HiveTaskRepository      _hive      = HiveTaskRepository();
  final FirestoreTaskRepository _firestore = FirestoreTaskRepository();
  final OfflineQueueRepository  _queue     = OfflineQueueRepository();

  @override
  TaskState build() => const TaskState(isLoading: true);

  /// Must be called after Hive boxes are open.
  Future<void> initialize() async {
    await _hive.init();
    await _queue.init();

    // Load from local storage immediately
    final local = _hive.getAll();
    state = state.copyWith(tasks: local, isLoading: false);

    // Attempt Firestore sync in background
    _syncFromFirestore();
  }

  Future<void> _syncFromFirestore() async {
    try {
      final remote = await _firestore.fetchAll();
      // Merge: remote wins for any task with newer updatedAt
      final mergedMap = <String, Task>{
        for (final t in state.tasks) t.id: t,
      };
      for (final remoteTask in remote) {
        final local = mergedMap[remoteTask.id];
        if (local == null || remoteTask.updatedAt.isAfter(local.updatedAt)) {
          mergedMap[remoteTask.id] = remoteTask;
        }
      }
      final merged = mergedMap.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _hive.saveAll(merged);
      state = state.copyWith(tasks: merged);
    } catch (_) {
      // Silently fail — we still show local data
    }
  }

  // ── CRUD ──────────────────────────────────────────────────────────────

  /// Creates a new task with the given parameters.
  Future<Task> createTask({
    required String title,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    String? note,
  }) async {
    final task = Task.create(
      id: _uuid.v4(),
      title: title,
      dueDate: dueDate,
      priority: priority,
      note: note,
    );

    // Optimistic local update
    await _hive.save(task);
    state = state.copyWith(tasks: [task, ...state.tasks]);

    // Sync
    await _syncWrite(
      () => _firestore.upsert(task),
      () => _queue.enqueueCreate(task),
    );

    return task;
  }

  /// Marks a task as completed (by ID or title fuzzy match).
  Future<void> completeTask(String idOrTitle) async {
    final task = _findTask(idOrTitle);
    if (task == null) return;

    final updated = task.copyWith(isCompleted: true);
    await _applyUpdate(updated);
    await _syncWrite(
      () => _firestore.markComplete(task.id),
      () => _queue.enqueueComplete(task.id),
    );
  }

  /// Marks a task as incomplete.
  Future<void> uncompleteTask(String idOrTitle) async {
    final task = _findTask(idOrTitle);
    if (task == null) return;

    final updated = task.copyWith(isCompleted: false);
    await _applyUpdate(updated);
    await _syncWrite(
      () => _firestore.markIncomplete(task.id),
      () => _queue.enqueueUncomplete(task.id),
    );
  }

  /// Deletes a task by ID or title.
  Future<void> deleteTask(String idOrTitle) async {
    final task = _findTask(idOrTitle);
    if (task == null) return;

    await _hive.delete(task.id);
    state = state.copyWith(
      tasks: state.tasks.where((t) => t.id != task.id).toList(),
    );
    await _syncWrite(
      () => _firestore.delete(task.id),
      () => _queue.enqueueDelete(task.id),
    );
  }

  /// Directly toggles completion (used from UI checkbox).
  Future<void> toggleTask(String taskId) async {
    final task = _findTask(taskId);
    if (task == null) return;
    if (task.isCompleted) {
      await uncompleteTask(taskId);
    } else {
      await completeTask(taskId);
    }
  }

  /// Updates the title / dueDate of a task.
  Future<void> updateTask(
    String idOrTitle, {
    String? newTitle,
    DateTime? newDueDate,
    TaskPriority? newPriority,
  }) async {
    final task = _findTask(idOrTitle);
    if (task == null) return;

    final updated = task.copyWith(
      title: newTitle,
      dueDate: newDueDate,
      priority: newPriority,
    );
    await _applyUpdate(updated);
    await _syncWrite(
      () => _firestore.upsert(updated),
      () => _queue.enqueueUpdate(updated),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Finds a task by exact ID or fuzzy title match (case-insensitive contains).
  Task? _findTask(String idOrTitle) {
    final lower = idOrTitle.toLowerCase();
    try {
      // Try exact ID first
      return state.tasks.firstWhere((t) => t.id == idOrTitle);
    } catch (_) {}
    try {
      return state.tasks.firstWhere(
          (t) => t.title.toLowerCase().contains(lower));
    } catch (_) {
      return null;
    }
  }

  Future<void> _applyUpdate(Task updated) async {
    await _hive.save(updated);
    state = state.copyWith(
      tasks: state.tasks
          .map((t) => t.id == updated.id ? updated : t)
          .toList(),
    );
  }

  /// Tries the online action; if it fails or we're offline, enqueues instead.
  Future<void> _syncWrite(
    Future<void> Function() onlineAction,
    Future<void> Function() queueAction,
  ) async {
    try {
      await onlineAction();
    } catch (_) {
      await queueAction();
      // Update sync status
      ref.read(syncProvider.notifier).state = ref.read(syncProvider).copyWith(
        status: SyncStatus.offline,
        pendingCommands: _queue.pendingCount,
      );
    }
  }

  // ── Query helpers ─────────────────────────────────────────────────────

  /// Returns tasks matching a search query.
  List<Task> search(String query) {
    final lower = query.toLowerCase();
    return state.tasks.where((t) => t.title.toLowerCase().contains(lower)).toList();
  }

  /// Forces a full refresh from Firestore.
  Future<void> refresh() => _syncFromFirestore();
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(
  TaskNotifier.new,
);
