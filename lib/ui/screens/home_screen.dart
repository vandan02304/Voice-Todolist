import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task_model.dart';
import '../../providers/speech_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/task_provider.dart';
import '../../services/voice_command_service.dart';
import '../theme/app_theme.dart';
import '../widgets/mic_button.dart';
import '../widgets/sync_status_chip.dart';
import '../widgets/task_tile.dart';
import '../widgets/voice_result_sheet.dart';

/// Main home screen.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Initialize tasks
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Voice ─────────────────────────────────────────────────────────────

  Future<void> _onMicTap() async {
    final speech = ref.read(speechProvider.notifier);
    final isListening = ref.read(speechProvider).state == SpeechState.listening;

    if (isListening) {
      await speech.stopListening();
      return;
    }

    await speech.startListening(
      onResult: (text) async {
        final service = ref.read(voiceCommandServiceProvider);
        final result  = await service.execute(text);
        if (mounted) {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => VoiceResultSheet(result: result),
          );
        }
      },
    );
  }

  // ── Add task manually ─────────────────────────────────────────────────

  Future<void> _showAddTaskDialog() async {
    final titleCtrl = TextEditingController();
    DateTime? dueDate;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Task', style: AppTheme.heading2),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                autofocus: true,
                style: AppTheme.body,
                decoration: InputDecoration(
                  hintText: 'Task title…',
                  hintStyle: AppTheme.bodySmall,
                  filled: true,
                  fillColor: const Color(0xFF282840),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setDlgState(() => dueDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282840),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF9090B0)),
                      const SizedBox(width: 8),
                      Text(
                        dueDate != null
                            ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                            : 'Set due date (optional)',
                        style: AppTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (titleCtrl.text.trim().isNotEmpty) {
                  ref.read(taskProvider.notifier).createTask(
                    title: titleCtrl.text.trim(),
                    dueDate: dueDate,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final taskState  = ref.watch(taskProvider);
    final syncState  = ref.watch(syncProvider);
    final speechSt   = ref.watch(speechProvider);
    final isListening = speechSt.state == SpeechState.listening;

    final incomplete = _filter(taskState.incomplete);
    final completed  = _filter(taskState.completed);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingMd, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Voice Todo', style: AppTheme.heading1),
                          Text('Manage tasks with your voice',
                              style: AppTheme.bodySmall),
                        ],
                      ),
                    ),
                    SyncStatusChip(syncState: syncState),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 26),
                      color: const Color(0xFF6C63FF),
                      onPressed: _showAddTaskDialog,
                    ),
                  ],
                ),
              ),

              // ── Listening banner ────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isListening ? 52 : 0,
                child: isListening
                    ? Container(
                        margin: const EdgeInsets.fromLTRB(
                            AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingMd, 0),
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMd),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusChip),
                          border: Border.all(
                              color: const Color(0xFFE53935).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.graphic_eq_rounded,
                                color: Color(0xFFE53935), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                speechSt.recognizedText.isEmpty
                                    ? 'Listening…'
                                    : speechSt.recognizedText,
                                style: AppTheme.bodySmall.copyWith(
                                    color: const Color(0xFFE53935)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Search bar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingMd, 0),
                child: TextField(
                  controller: _searchCtrl,
                  style: AppTheme.body,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search tasks…',
                    hintStyle: AppTheme.bodySmall,
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 20, color: Color(0xFF9090B0)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                size: 18, color: Color(0xFF9090B0)),
                            onPressed: () =>
                                setState(() { _searchQuery = ''; _searchCtrl.clear(); }),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFF1E1E2E),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // ── Tab bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd, AppTheme.spacingMd, AppTheme.spacingMd, 0),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    dividerHeight: 0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip + 2),
                    ),
                    labelStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    unselectedLabelColor: const Color(0xFF9090B0),
                    tabs: [
                      Tab(text: 'Pending (${incomplete.length})'),
                      Tab(text: 'Done (${completed.length})'),
                    ],
                  ),
                ),
              ),

              // ── Task list ────────────────────────────────────────────
              Expanded(
                child: taskState.isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: Color(0xFF6C63FF)))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _TaskList(tasks: incomplete, emptyMessage: 'No pending tasks 🎉\nTap mic and say "Create task"'),
                          _TaskList(tasks: completed,  emptyMessage: 'No completed tasks yet'),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),

      // ── Mic FAB ──────────────────────────────────────────────────────
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: MicButton(
          isListening: isListening,
          soundLevel: speechSt.soundLevel,
          onTap: _onMicTap,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  List<Task> _filter(List<Task> tasks) {
    if (_searchQuery.isEmpty) return tasks;
    final q = _searchQuery.toLowerCase();
    return tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
  }
}

/// A list pane showing tasks or an empty state.
class _TaskList extends ConsumerWidget {
  final List<Task> tasks;
  final String emptyMessage;

  const _TaskList({required this.tasks, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return _EmptyState(message: emptyMessage);
    }
    return ListView.builder(
      padding: const EdgeInsets.only(
          top: AppTheme.spacingMd, bottom: 100),
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final task = tasks[i];
        return TaskTile(
          task: task,
          onToggle: () => ref.read(taskProvider.notifier).toggleTask(task.id),
          onDelete: () => ref.read(taskProvider.notifier).deleteTask(task.id),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline_rounded,
                  size: 40, color: Color(0xFF6C63FF)),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodySmall.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
