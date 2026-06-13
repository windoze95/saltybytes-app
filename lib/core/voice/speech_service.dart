import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Provides the on-device speech-to-text service used by cooking mode.
final speechServiceProvider = Provider<SpeechService>((ref) {
  return SpeechToTextService();
});

/// Thin abstraction over on-device speech recognition so providers can be
/// tested with a fake implementation.
abstract class SpeechService {
  /// Initializes the recognizer, requesting microphone / speech permission
  /// when needed. Returns false when speech recognition is unavailable or
  /// permission was denied.
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  });

  /// Starts listening. [onResult] receives partial transcripts as the user
  /// speaks; `isFinal` is true once, for the final transcript.
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  });

  /// Stops listening; the recognizer delivers a final result for anything
  /// recognized so far. Safe to call when not listening.
  Future<void> stop();

  bool get isListening;
}

/// Default [SpeechService] backed by the speech_to_text plugin.
class SpeechToTextService implements SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  // The plugin only registers status/error listeners on the FIRST
  // initialize call, so route through mutable fields to allow callers
  // (e.g. a re-created cooking notifier) to swap their callbacks.
  void Function(String status)? _onStatus;
  void Function(String error)? _onError;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) {
    _onStatus = onStatus;
    _onError = onError;
    return _speech.initialize(
      onStatus: (status) => _onStatus?.call(status),
      onError: (error) => _onError?.call(error.errorMsg),
    );
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) {
    return _speech.listen(
      onResult: (result) =>
          onResult(result.recognizedWords, result.finalResult),
      pauseFor: const Duration(seconds: 3),
      listenFor: const Duration(seconds: 30),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  bool get isListening => _speech.isListening;
}
