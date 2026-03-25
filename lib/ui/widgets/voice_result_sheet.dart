import 'package:flutter/material.dart';
import '../../nlp/command_parser.dart';
import '../../services/voice_command_service.dart';
import '../theme/app_theme.dart';

/// Bottom sheet that shows the recognized voice text, parsed command, and result.
class VoiceResultSheet extends StatelessWidget {
  final VoiceCommandResult result;

  const VoiceResultSheet({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppTheme.spacingLg,
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingLg + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF3E3E5E),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),

          // Status icon + header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: result.success
                      ? AppTheme.priorityLow.withOpacity(0.15)
                      : AppTheme.priorityHigh.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  result.success ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: result.success ? AppTheme.priorityLow : AppTheme.priorityHigh,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.success ? 'Command Executed' : 'Command Failed',
                      style: AppTheme.heading2.copyWith(fontSize: 16),
                    ),
                    Text(
                      _actionLabel(result.parsed.action),
                      style: AppTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacingMd),
          const Divider(),
          const SizedBox(height: AppTheme.spacingMd),

          // Recognized text
          Text('You said:', style: AppTheme.label),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF282840),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              '"${result.transcript}"',
              style: AppTheme.body.copyWith(
                fontStyle: FontStyle.italic,
                color: const Color(0xFFB0B0D0),
              ),
            ),
          ),

          const SizedBox(height: AppTheme.spacingMd),

          // Result message
          Text('Result:', style: AppTheme.label),
          const SizedBox(height: 4),
          Text(result.feedbackMessage, style: AppTheme.body),

          // Parsed details if relevant
          if (result.parsed.taskTitle != null) ...[
            const SizedBox(height: AppTheme.spacingMd),
            _ParsedDetail(label: 'Task', value: result.parsed.taskTitle!),
          ],
          if (result.parsed.dueDate != null)
            _ParsedDetail(
              label: 'Due',
              value: _formatDate(result.parsed.dueDate!),
            ),

          const SizedBox(height: AppTheme.spacingLg),

          // Dismiss
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
              ),
              child: const Text('Done', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  String _actionLabel(VoiceAction action) {
    return switch (action) {
      VoiceAction.create    => 'Create Task',
      VoiceAction.complete  => 'Complete Task',
      VoiceAction.uncomplete=> 'Reopen Task',
      VoiceAction.delete    => 'Delete Task',
      VoiceAction.list      => 'List Tasks',
      VoiceAction.update    => 'Update Task',
      VoiceAction.unknown   => 'Unknown Command',
    };
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Today';
    if (d.year == now.year && d.month == now.month && d.day == now.day + 1) return 'Tomorrow';
    return '${d.day}/${d.month}/${d.year}';
  }
}

class _ParsedDetail extends StatelessWidget {
  final String label;
  final String value;
  const _ParsedDetail({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(label, style: AppTheme.label),
          ),
          const SizedBox(width: 8),
          Text(value, style: AppTheme.bodySmall.copyWith(color: const Color(0xFFB0B0D0))),
        ],
      ),
    );
  }
}
