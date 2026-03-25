import 'package:hive/hive.dart';

part 'offline_command.g.dart';

/// Types of commands that can be queued for offline replay.
@HiveType(typeId: 2)
enum CommandType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
  @HiveField(3)
  complete,
  @HiveField(4)
  uncomplete,
}

/// Represents a task mutation that was performed while offline.
/// Stored in Hive and replayed against Firestore when connectivity is restored.
@HiveType(typeId: 3)
class OfflineCommand extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final CommandType type;

  @HiveField(2)
  final String taskId;

  /// JSON-serializable payload (task fields needed to replay the command).
  @HiveField(3)
  final Map<dynamic, dynamic> payload;

  @HiveField(4)
  final DateTime timestamp;

  OfflineCommand({
    required this.id,
    required this.type,
    required this.taskId,
    required this.payload,
    required this.timestamp,
  });

  @override
  String toString() =>
      'OfflineCommand(id: $id, type: $type, taskId: $taskId)';
}
