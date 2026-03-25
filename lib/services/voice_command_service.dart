import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/models/task_model.dart';
import '../nlp/command_parser.dart';
import '../providers/task_provider.dart';
import '../providers/tts_provider.dart';

/// Result of a voice command execution, shown in the UI overlay.
class VoiceCommandResult {
  final String transcript;
  final ParsedCommand parsed;
  final String feedbackMessage;
  final bool success;

  const VoiceCommandResult({
    required this.transcript,
    required this.parsed,
    required this.feedbackMessage,
    required this.success,
  });
}

/// Service that bridges the STT transcript → NLP parser → task actions → TTS.
/// Exposes a single [execute] method.
class VoiceCommandService {
  final Ref _ref;
  VoiceCommandService(this._ref);

  /// Parses [transcript] and executes the corresponding task action.
  /// Returns a [VoiceCommandResult] with the result for display.
  Future<VoiceCommandResult> execute(String transcript) async {
    final parsed = CommandParser.parse(transcript);
    String feedback;
    bool success = true;

    try {
      switch (parsed.action) {
        case VoiceAction.create:
          if (parsed.taskTitle == null || parsed.taskTitle!.isEmpty) {
            feedback = "Sorry, I couldn't understand the task title. Try: Create task Buy groceries";
            success = false;
            break;
          }
          await _ref.read(taskProvider.notifier).createTask(
            title: parsed.taskTitle!,
            dueDate: parsed.dueDate,
            priority: parsed.priority ?? TaskPriority.medium,
          );
          feedback = 'Task created: ${parsed.taskTitle}';
          if (parsed.dueDate != null) {
            feedback += ', due ${DateFormat('MMMM d').format(parsed.dueDate!)}';
          }

        case VoiceAction.complete:
          if (parsed.taskTitle == null) {
            feedback = 'Which task should I complete?';
            success = false;
            break;
          }
          await _ref.read(taskProvider.notifier).completeTask(parsed.taskTitle!);
          feedback = 'Task completed: ${parsed.taskTitle}';

        case VoiceAction.uncomplete:
          if (parsed.taskTitle == null) {
            feedback = 'Which task should I reopen?';
            success = false;
            break;
          }
          await _ref.read(taskProvider.notifier).uncompleteTask(parsed.taskTitle!);
          feedback = 'Task reopened: ${parsed.taskTitle}';

        case VoiceAction.delete:
          if (parsed.taskTitle == null) {
            feedback = 'Which task should I delete?';
            success = false;
            break;
          }
          await _ref.read(taskProvider.notifier).deleteTask(parsed.taskTitle!);
          feedback = 'Task deleted: ${parsed.taskTitle}';

        case VoiceAction.list:
          final tasks = _ref.read(taskProvider).incomplete;
          if (tasks.isEmpty) {
            feedback = 'You have no pending tasks. Great job!';
          } else {
            final titles = tasks.take(3).map((t) => t.title).join(', ');
            feedback = 'You have ${tasks.length} pending task${tasks.length == 1 ? '' : 's'}: $titles';
            if (tasks.length > 3) feedback += ' and ${tasks.length - 3} more.';
          }

        case VoiceAction.update:
          // Format: "update task <old title> to <new title>"
          final title = parsed.taskTitle;
          if (title == null) {
            feedback = 'Which task should I update and to what?';
            success = false;
            break;
          }
          final parts = title.split(RegExp(r'\s+to\s+', caseSensitive: false));
          if (parts.length < 2) {
            feedback = 'Say: Update task old title to new title';
            success = false;
            break;
          }
          await _ref.read(taskProvider.notifier).updateTask(
            parts[0].trim(),
            newTitle: parts[1].trim(),
            newDueDate: parsed.dueDate,
          );
          feedback = 'Task updated to: ${parts[1].trim()}';

        case VoiceAction.unknown:
          feedback = "I didn't understand that. Try: Create task, Complete task, Delete task, or List tasks.";
          success = false;
      }
    } catch (e) {
      feedback = 'Something went wrong: ${e.toString()}';
      success = false;
    }

    // Speak the feedback
    await _ref.read(ttsProvider.notifier).speak(feedback);

    return VoiceCommandResult(
      transcript: transcript,
      parsed: parsed,
      feedbackMessage: feedback,
      success: success,
    );
  }
}

final voiceCommandServiceProvider = Provider<VoiceCommandService>(
  (ref) => VoiceCommandService(ref),
);
