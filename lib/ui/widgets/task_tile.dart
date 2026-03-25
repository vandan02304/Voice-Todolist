import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/task_model.dart';
import '../theme/app_theme.dart';

/// A card widget displaying a single [Task] with completion toggle and delete.
class TaskTile extends StatefulWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _strikeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: widget.task.isCompleted ? 1.0 : 0.0,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _strikeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(TaskTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.task.isCompleted != oldWidget.task.isCompleted) {
      if (widget.task.isCompleted) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _priorityColor() {
    switch (widget.task.priority) {
      case TaskPriority.high:
        return AppTheme.priorityHigh;
      case TaskPriority.low:
        return AppTheme.priorityLow;
      case TaskPriority.medium:
        return AppTheme.priorityMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOverdue = widget.task.dueDate != null &&
        widget.task.dueDate!.isBefore(DateTime.now()) &&
        !widget.task.isCompleted;

    return ScaleTransition(
      scale: _scaleAnim,
      child: Container(
        margin: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingXs + 2),
        decoration: BoxDecoration(
          color: const Color(0xFF282840),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: _priorityColor().withOpacity(0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: _priorityColor().withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Dismissible(
          key: ValueKey(widget.task.id),
          direction: DismissDirection.endToStart,
          background: _deleteBackground(),
          onDismissed: (_) => widget.onDelete(),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMd, vertical: AppTheme.spacingMd - 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Priority strip ────────────────────────────────────────
                Container(
                  width: 4,
                  height: 44,
                  margin: const EdgeInsets.only(right: 12, top: 2),
                  decoration: BoxDecoration(
                    color: _priorityColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),

                // ── Checkbox ──────────────────────────────────────────────
                Transform.scale(
                  scale: 1.15,
                  child: Checkbox(
                    value: widget.task.isCompleted,
                    onChanged: (_) => widget.onToggle(),
                  ),
                ),

                const SizedBox(width: 6),

                // ── Title + due date ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _strikeAnim,
                        builder: (context, child) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            child!,
                            if (_strikeAnim.value > 0)
                              Positioned(
                                left: 0,
                                right: 0,
                                child: ClipRect(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _strikeAnim.value,
                                    child: Container(
                                      height: 1.5,
                                      color: AppTheme.onSurfaceLow,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        child: Text(
                          widget.task.title,
                          style: AppTheme.body.copyWith(
                            color: widget.task.isCompleted
                                ? const Color(0xFF9090B0)
                                : const Color(0xFFE0E0F0),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.task.dueDate != null) ...[
                        const SizedBox(height: 4),
                        _DueDateChip(
                          date: widget.task.dueDate!,
                          isOverdue: isOverdue,
                        ),
                      ],
                    ],
                  ),
                ),

                // ── Delete button ─────────────────────────────────────────
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: const Color(0xFF9090B0),
                  onPressed: widget.onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 24),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.priorityHigh.withOpacity(0.2),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: const Icon(Icons.delete_rounded, color: AppTheme.priorityHigh),
    );
  }
}

class _DueDateChip extends StatelessWidget {
  final DateTime date;
  final bool isOverdue;

  const _DueDateChip({required this.date, required this.isOverdue});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('MMM d').format(date);
    final color = isOverdue ? AppTheme.priorityHigh : const Color(0xFF9090B0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
          size: 11,
          color: color,
        ),
        const SizedBox(width: 3),
        Text(
          isOverdue ? 'Overdue · $formatted' : formatted,
          style: AppTheme.label.copyWith(color: color),
        ),
      ],
    );
  }
}

// (extension removed — use AppTheme.onSurfaceLow directly)
