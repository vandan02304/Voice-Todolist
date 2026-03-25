import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/speech_provider.dart';
import '../providers/tts_provider.dart';
import '../providers/task_provider.dart';
import 'guided_voice_state.dart';

final guidedVoiceProvider = NotifierProvider<GuidedVoiceNotifier, GuidedVoiceState>(
  GuidedVoiceNotifier.new,
);

class GuidedVoiceNotifier extends Notifier<GuidedVoiceState> {
  @override
  GuidedVoiceState build() => const GuidedVoiceState();

  Future<void> startFlow() async {
    // 1. Ask Title
    state = state.copyWith(step: GuidedVoiceStep.askingTitle, prompt: 'What is the task name?');
    await ref.read(ttsProvider.notifier).speak('What is the task name?');
    
    // 2. Listen Title
    state = state.copyWith(step: GuidedVoiceStep.listeningTitle);
    final title = await ref.read(speechProvider.notifier).listenOnce();
    
    if (title.isEmpty) {
      await _abort('I didn\'t hear a task name. Canceling.');
      return;
    }
    state = state.copyWith(title: title);

    // 3. Ask Date
    state = state.copyWith(step: GuidedVoiceStep.askingDate, prompt: 'What is the completion date and time?');
    await ref.read(ttsProvider.notifier).speak('What is the completion date and time?');

    // 4. Listen Date
    state = state.copyWith(step: GuidedVoiceStep.listeningDate);
    final dateStr = await ref.read(speechProvider.notifier).listenOnce(timeout: const Duration(seconds: 10));
    
    DateTime? dueDate;
    if (dateStr.isNotEmpty) {
      dueDate = _parseBasicDate(dateStr);
    }

    state = state.copyWith(
      step: GuidedVoiceStep.saving,
      dueDate: dueDate,
      prompt: 'Saving task...',
    );

    // 5. Save locally using Hive & Sync to Firestore
    final transcript = '[Title spoken: "$title"] [Date spoken: "${dateStr.isEmpty ? 'None' : dateStr}"]';
    await ref.read(taskProvider.notifier).createTask(
      title: title,
      dueDate: dueDate,
      voiceTranscript: transcript,
    );

    // 6. Confirm
    state = state.copyWith(step: GuidedVoiceStep.success, prompt: 'Task added successfully');
    await ref.read(ttsProvider.notifier).speak('Task added successfully.');
    
    // Reset after delay
    await Future.delayed(const Duration(seconds: 3));
    if (state.step == GuidedVoiceStep.success) {
      state = const GuidedVoiceState();
    }
  }

  Future<void> _abort(String message) async {
    state = state.copyWith(step: GuidedVoiceStep.error, prompt: message);
    await ref.read(ttsProvider.notifier).speak(message);
    await Future.delayed(const Duration(seconds: 3));
    state = const GuidedVoiceState();
  }

  void cancelFlow() {
    ref.read(ttsProvider.notifier).stop();
    ref.read(speechProvider.notifier).stopListening();
    state = const GuidedVoiceState();
  }

  /// Extremely basic parsing as requested
  DateTime? _parseBasicDate(String input) {
    final lower = input.toLowerCase();
    final now = DateTime.now();
    if (lower.contains('today')) {
      return DateTime(now.year, now.month, now.day, 23, 59);
    } else if (lower.contains('tomorrow')) {
      return DateTime(now.year, now.month, now.day + 1, 23, 59);
    } else if (lower.contains('next week')) {
      return now.add(const Duration(days: 7));
    }
    return null; // Fallback
  }
}
