import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/offline_command.dart';
import '../models/task_model.dart';

/// Repository for managing the offline command queue.
/// Commands are stored in Hive and replayed against Firestore when online.
class OfflineQueueRepository {
  static const String _boxName = 'offline_commands';
  static const _uuid = Uuid();

  Box<OfflineCommand>? _box;

  Box<OfflineCommand> get box {
    assert(_box != null && _box!.isOpen, 'Offline queue box not open.');
    return _box!;
  }

  /// Opens the Hive box.
  Future<void> init() async {
    if (Hive.isBoxOpen(_boxName)) {
      _box = Hive.box<OfflineCommand>(_boxName);
    } else {
      _box = await Hive.openBox<OfflineCommand>(_boxName);
    }
  }

  /// Adds a command to the queue.
  Future<void> enqueue({
    required CommandType type,
    required String taskId,
    Map<String, dynamic> payload = const {},
  }) async {
    final cmd = OfflineCommand(
      id: _uuid.v4(),
      type: type,
      taskId: taskId,
      payload: payload,
      timestamp: DateTime.now(),
    );
    await box.put(cmd.id, cmd);
  }

  /// Enqueues a "create" command for a Task.
  Future<void> enqueueCreate(Task task) async {
    await enqueue(
      type: CommandType.create,
      taskId: task.id,
      payload: task.toFirestore(),
    );
  }

  /// Enqueues an "update" command.
  Future<void> enqueueUpdate(Task task) async {
    await enqueue(
      type: CommandType.update,
      taskId: task.id,
      payload: task.toFirestore(),
    );
  }

  /// Enqueues a "delete" command.
  Future<void> enqueueDelete(String taskId) async {
    await enqueue(type: CommandType.delete, taskId: taskId);
  }

  /// Enqueues a "complete" command.
  Future<void> enqueueComplete(String taskId) async {
    await enqueue(type: CommandType.complete, taskId: taskId);
  }

  /// Enqueues an "uncomplete" command.
  Future<void> enqueueUncomplete(String taskId) async {
    await enqueue(type: CommandType.uncomplete, taskId: taskId);
  }

  /// Returns all pending commands ordered by timestamp.
  List<OfflineCommand> getPending() {
    final commands = box.values.toList();
    commands.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return commands;
  }

  /// Removes a command after it has been successfully replayed.
  Future<void> remove(String commandId) async {
    await box.delete(commandId);
  }

  /// Clears all pending commands (e.g., after a successful full sync).
  Future<void> clearAll() async {
    await box.clear();
  }

  /// Returns the number of pending commands.
  int get pendingCount => box.length;

  bool get hasPending => box.isNotEmpty;
}
