import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/models/offline_command.dart';
import 'data/models/task_model.dart';
import 'firebase_options.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Initialize Hive ─────────────────────────────────────────────────
  await Hive.initFlutter();

  // Register all Hive type adapters
  Hive.registerAdapter(TaskPriorityAdapter());
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(CommandTypeAdapter());
  Hive.registerAdapter(OfflineCommandAdapter());

  // ── 2. Initialize Firebase ─────────────────────────────────────────────
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase might not be configured yet — app still works offline.
    debugPrint('[Firebase] Initialization failed: $e');
    debugPrint('[Firebase] Running in offline-only mode.');
  }

  // ── 3. Run app ─────────────────────────────────────────────────────────
  runApp(
    const ProviderScope(
      child: VoiceTodoApp(),
    ),
  );
}

/// Root application widget.
class VoiceTodoApp extends StatelessWidget {
  const VoiceTodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Todo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const HomeScreen(),
    );
  }
}
