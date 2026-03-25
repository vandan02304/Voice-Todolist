import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Possible states of the speech recognition engine.
enum SpeechState {
  uninitialized,
  ready,
  listening,
  processing,
  unavailable,
  error,
}

/// State object for speech-to-text.
class SpeechNotifierState {
  final SpeechState state;
  final String recognizedText;
  final String errorMessage;
  final double soundLevel; // 0.0 – 1.0 mic amplitude

  const SpeechNotifierState({
    this.state = SpeechState.uninitialized,
    this.recognizedText = '',
    this.errorMessage = '',
    this.soundLevel = 0.0,
  });

  SpeechNotifierState copyWith({
    SpeechState? state,
    String? recognizedText,
    String? errorMessage,
    double? soundLevel,
  }) {
    return SpeechNotifierState(
      state: state ?? this.state,
      recognizedText: recognizedText ?? this.recognizedText,
      errorMessage: errorMessage ?? this.errorMessage,
      soundLevel: soundLevel ?? this.soundLevel,
    );
  }
}

/// Riverpod notifier managing the speech_to_text lifecycle.
class SpeechNotifier extends Notifier<SpeechNotifierState> {
  final SpeechToText _speech = SpeechToText();

  @override
  SpeechNotifierState build() => const SpeechNotifierState();

  /// Initialises the STT engine. Must be called before listening.
  Future<bool> initialize() async {
    final available = await _speech.initialize(
      onStatus: _onStatus,
      onError: (error) {
        state = state.copyWith(
          state: SpeechState.error,
          errorMessage: error.errorMsg,
        );
      },
    );

    if (available) {
      state = state.copyWith(state: SpeechState.ready);
    } else {
      state = state.copyWith(state: SpeechState.unavailable);
    }
    return available;
  }

  /// Starts listening and returns the transcript via [onResult].
  Future<void> startListening({required void Function(String text) onResult}) async {
    if (state.state == SpeechState.uninitialized) {
      final ok = await initialize();
      if (!ok) return;
    }

    if (_speech.isListening) {
      await stopListening();
      return;
    }

    state = state.copyWith(state: SpeechState.listening, recognizedText: '');

    await _speech.listen(
      onResult: (result) {
        state = state.copyWith(
          recognizedText: result.recognizedWords,
          state: result.finalResult ? SpeechState.processing : SpeechState.listening,
        );
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      onSoundLevelChange: (level) {
        final normalized = ((level + 2) / 12).clamp(0.0, 1.0);
        state = state.copyWith(soundLevel: normalized);
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  /// Listens to a single utterance and returns a Future with the recognized text.
  Future<String> listenOnce({Duration timeout = const Duration(seconds: 10)}) async {
    if (state.state == SpeechState.uninitialized) await initialize();
    
    final completer = Completer<String>();
    String lastRecognized = '';

    await startListening(onResult: (text) {
      lastRecognized = text;
      if (state.state == SpeechState.processing && !completer.isCompleted) {
        completer.complete(text);
      }
    });

    // Polling loop to detect when speech recognition stops naturally
    int elapsed = 0;
    while (!completer.isCompleted && elapsed < timeout.inMilliseconds) {
      await Future.delayed(const Duration(milliseconds: 100));
      elapsed += 100;
      if (!isListening && state.state != SpeechState.listening && state.state != SpeechState.processing) {
        if (!completer.isCompleted) completer.complete(lastRecognized);
        break;
      }
    }

    if (!completer.isCompleted) {
      await stopListening();
      completer.complete(lastRecognized);
    }

    return completer.future;
  }

  /// Stops listening and transitions to processing state.
  Future<void> stopListening() async {
    await _speech.stop();
    state = state.copyWith(
      state: SpeechState.ready,
      soundLevel: 0.0,
    );
  }

  /// Cancels listening without processing results.
  Future<void> cancelListening() async {
    await _speech.cancel();
    state = state.copyWith(
      state: SpeechState.ready,
      recognizedText: '',
      soundLevel: 0.0,
    );
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (state.state == SpeechState.listening) {
        state = state.copyWith(state: SpeechState.ready, soundLevel: 0.0);
      }
    }
  }

  bool get isListening => _speech.isListening;
}

final speechProvider = NotifierProvider<SpeechNotifier, SpeechNotifierState>(
  SpeechNotifier.new,
);
