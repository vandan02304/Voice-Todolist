import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/offline_command.dart';
import '../data/repositories/firestore_task_repository.dart';
import '../data/repositories/hive_task_repository.dart';
import '../data/repositories/offline_queue_repository.dart';
import '../data/models/task_model.dart';

/// Describes the current synchronisation status.
enum SyncStatus { synced, syncing, offline, error }

/// State for the sync notifier.
class SyncState {
  final SyncStatus status;
  final int pendingCommands;
  final String? errorMessage;

  const SyncState({
    this.status = SyncStatus.synced,
    this.pendingCommands = 0,
    this.errorMessage,
  });

  SyncState copyWith({
    SyncStatus? status,
    int? pendingCommands,
    String? errorMessage,
  }) =>
      SyncState(
        status: status ?? this.status,
        pendingCommands: pendingCommands ?? this.pendingCommands,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

/// Monitors connectivity and replays the offline command queue against
/// Firestore whenever the device comes back online.
class SyncNotifier extends Notifier<SyncState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = false;

  @override
  SyncState build() => const SyncState();

  final _hiveRepo      = HiveTaskRepository();
  final _firestoreRepo = FirestoreTaskRepository();
  final _queueRepo     = OfflineQueueRepository();

  /// Must be called once after Hive is open.
  Future<void> initialize({
    required HiveTaskRepository hiveRepo,
    required FirestoreTaskRepository firestoreRepo,
    required OfflineQueueRepository queueRepo,
  }) async {
    // Start monitoring connectivity
    final connectivity = Connectivity();
    final initial = await connectivity.checkConnectivity();
    _handleConnectivityChange(initial);

    _connectivitySub = connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final connected = results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);

    if (connected && !_isOnline) {
      _isOnline = true;
      _processQueue();
    } else if (!connected) {
      _isOnline = false;
      state = state.copyWith(status: SyncStatus.offline);
    }
  }

  bool get isOnline => _isOnline;

  /// Manually triggers a queue flush. Called by task_provider when a
  /// mutation is performed while online.
  Future<void> flushQueue({
    required HiveTaskRepository hiveRepo,
    required FirestoreTaskRepository firestoreRepo,
    required OfflineQueueRepository queueRepo,
  }) async {
    if (!_isOnline) return;
    await _replayQueue(hiveRepo, firestoreRepo, queueRepo);
  }

  Future<void> _processQueue() async {
    await _replayQueue(_hiveRepo, _firestoreRepo, _queueRepo);
  }

  Future<void> _replayQueue(
    HiveTaskRepository hive,
    FirestoreTaskRepository firestore,
    OfflineQueueRepository queue,
  ) async {
    final pending = queue.getPending();
    if (pending.isEmpty) {
      state = state.copyWith(status: SyncStatus.synced, pendingCommands: 0);
      return;
    }

    state = state.copyWith(
      status: SyncStatus.syncing,
      pendingCommands: pending.length,
    );

    for (final cmd in pending) {
      try {
        await _executeCommand(cmd, hive, firestore);
        await queue.remove(cmd.id);
      } catch (e) {
        state = state.copyWith(
          status: SyncStatus.error,
          errorMessage: e.toString(),
        );
        return;
      }
    }

    state = state.copyWith(status: SyncStatus.synced, pendingCommands: 0);
  }

  Future<void> _executeCommand(
    OfflineCommand cmd,
    HiveTaskRepository hive,
    FirestoreTaskRepository firestore,
  ) async {
    switch (cmd.type) {
      case CommandType.create:
      case CommandType.update:
        final task = Task.fromFirestore(Map<String, dynamic>.from(cmd.payload));
        await firestore.upsert(task);
        break;
      case CommandType.delete:
        await firestore.delete(cmd.taskId);
        break;
      case CommandType.complete:
        await firestore.markComplete(cmd.taskId);
        break;
      case CommandType.uncomplete:
        await firestore.markIncomplete(cmd.taskId);
        break;
    }
  }

  /// Queues a command for later (called by task_provider when offline).
  Future<void> enqueue(
    OfflineQueueRepository queueRepo,
    CommandType type,
    String taskId, {
    Map<String, dynamic> payload = const {},
  }) async {
    await queueRepo.enqueue(type: type, taskId: taskId, payload: payload);
    state = state.copyWith(
      status: SyncStatus.offline,
      pendingCommands: queueRepo.pendingCount,
    );
  }

  @override
  // ignore: override_on_non_overriding_member
  void dispose() {
    _connectivitySub?.cancel();
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);
