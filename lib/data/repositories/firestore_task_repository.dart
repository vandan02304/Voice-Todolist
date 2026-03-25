import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

/// Repository for Firestore CRUD operations.
/// All tasks are stored under `users/{uid}/tasks/{taskId}`.
class FirestoreTaskRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreTaskRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Returns the current user's tasks collection reference.
  /// Signs in anonymously if no user exists.
  Future<CollectionReference<Map<String, dynamic>>> get _tasksRef async {
    User? user = _auth.currentUser;
    if (user == null) {
      final result = await _auth.signInAnonymously();
      user = result.user!;
    }
    return _firestore.collection('users').doc(user.uid).collection('tasks');
  }

  /// Upserts a task to Firestore (merge: true avoids overwriting unset fields).
  Future<void> upsert(Task task) async {
    final ref = await _tasksRef;
    await ref.doc(task.id).set(task.toFirestore(), SetOptions(merge: true));
  }

  /// Deletes a task document from Firestore.
  Future<void> delete(String taskId) async {
    final ref = await _tasksRef;
    await ref.doc(taskId).delete();
  }

  /// Fetches all tasks once (used during initial load or full sync).
  Future<List<Task>> fetchAll() async {
    final ref = await _tasksRef;
    final snapshot = await ref.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Task.fromFirestore(doc.data()))
        .toList();
  }

  /// Returns a stream of all tasks (real-time updates).
  Future<Stream<List<Task>>> streamTasks() async {
    final ref = await _tasksRef;
    return ref
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Task.fromFirestore(d.data())).toList());
  }

  /// Marks a task as completed in Firestore.
  Future<void> markComplete(String taskId) async {
    final ref = await _tasksRef;
    await ref.doc(taskId).update({
      'status': 'completed',
      'isSynced': true,
    });
  }

  /// Marks a task as not completed in Firestore.
  Future<void> markIncomplete(String taskId) async {
    final ref = await _tasksRef;
    await ref.doc(taskId).update({
      'status': 'pending',
      'isSynced': true,
    });
  }
}
