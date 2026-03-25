/// Represents the step in the guided voice flow.
enum GuidedVoiceStep {
  idle,
  askingTitle,
  listeningTitle,
  askingDate,
  listeningDate,
  saving,
  success,
  error,
}

/// The state of the guided voice flow.
class GuidedVoiceState {
  final GuidedVoiceStep step;
  final String prompt;
  final String recognizedText;
  final String? title;
  final DateTime? dueDate;

  const GuidedVoiceState({
    this.step = GuidedVoiceStep.idle,
    this.prompt = '',
    this.recognizedText = '',
    this.title,
    this.dueDate,
  });

  GuidedVoiceState copyWith({
    GuidedVoiceStep? step,
    String? prompt,
    String? recognizedText,
    String? title,
    DateTime? dueDate,
  }) => GuidedVoiceState(
    step: step ?? this.step,
    prompt: prompt ?? this.prompt,
    recognizedText: recognizedText ?? this.recognizedText,
    title: title ?? this.title,
    dueDate: dueDate ?? this.dueDate,
  );
}
