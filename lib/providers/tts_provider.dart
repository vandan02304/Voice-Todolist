import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Riverpod notifier that wraps FlutterTts for voice feedback.
class TtsNotifier extends Notifier<bool> {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  @override
  bool build() => false; // false = not speaking

  Future<void> _init() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(() => state = false);
    _tts.setStartHandler(() => state = true);
    _initialized = true;
  }

  /// Speaks [text] aloud. Stops any currently playing speech first.
  Future<void> speak(String text) async {
    await _init();
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Stops the current speech immediately.
  Future<void> stop() async {
    await _tts.stop();
    state = false;
  }

  bool get isSpeaking => state;
}

final ttsProvider = NotifierProvider<TtsNotifier, bool>(TtsNotifier.new);
