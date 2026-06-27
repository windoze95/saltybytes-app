import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vosk_flutter_2/vosk_flutter_2.dart';

/// Provides the on-device wake-word engine used by cooking mode.
final wakeWordServiceProvider = Provider<WakeWordService>((ref) {
  return VoskWakeWordService();
});

/// On-device "Gordon" wake-word detection. Runs entirely on the phone — no
/// audio leaves the device and no cloud service is involved.
abstract class WakeWordService {
  /// Whether the engine is configured. When false, hands-free falls back to
  /// manual tap-to-talk.
  bool get isConfigured;

  /// Starts always-listening wake-word detection. [onWake] fires on each
  /// detection. Returns false when it could not start (model not yet available,
  /// mic permission denied, or an engine error) — the caller then uses
  /// tap-to-talk.
  Future<bool> start({
    required void Function() onWake,
    required void Function(String error) onError,
  });

  /// Stops detection and releases the microphone. Safe to call when stopped.
  Future<void> stop();
}

/// [WakeWordService] backed by [Vosk](https://alphacephei.com/vosk/) — a free,
/// open-source, offline speech recognizer. We constrain it to a small grammar
/// of "Gordon" variants so it behaves as a focused keyword spotter rather
/// than open-ended dictation.
///
/// The ~40 MB English model is downloaded once via [ModelLoader.loadFromNetwork]
/// and cached on device (offline thereafter); it is never bundled in the app.
/// To avoid blocking cook-mode entry, the first session (before the model is
/// cached) starts the download in the background and reports `false` so
/// hands-free uses tap-to-talk until the model is ready. Override the model URL
/// (e.g. to self-host the zip) with `--dart-define=VOSK_MODEL_URL=...`.
class VoskWakeWordService implements WakeWordService {
  VoskWakeWordService({
    String? modelUrl,
    List<String>? wakePhrases,
    int sampleRate = 16000,
  })  : _modelUrl = (modelUrl == null || modelUrl.isEmpty)
            ? _resolveModelUrl()
            : modelUrl,
        _wakePhrases = wakePhrases ?? _defaultPhrases,
        _sampleRate = sampleRate;

  final String _modelUrl;
  final List<String> _wakePhrases;
  final int _sampleRate;

  Model? _model;
  String? _modelPath;
  Recognizer? _recognizer;
  SpeechService? _speechService;
  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _resultSub;
  void Function()? _onWake;

  static const _defaultModelUrl =
      'https://alphacephei.com/vosk/models/vosk-model-small-en-us-0.15.zip';

  /// Liberal phrase set to absorb common mishearings of "Gordon".
  static const _defaultPhrases = [
    'gordon',
    'gordan',
    'gorden',
    'yo gordon',
    'hey gordon',
    'gordon ramsay',
  ];

  static String _resolveModelUrl() {
    const fromEnv = String.fromEnvironment('VOSK_MODEL_URL');
    return fromEnv.isNotEmpty ? fromEnv : _defaultModelUrl;
  }

  String get _modelName {
    final last = _modelUrl.split('/').last;
    return last.endsWith('.zip') ? last.substring(0, last.length - 4) : last;
  }

  @override
  bool get isConfigured => _modelUrl.isNotEmpty;

  @override
  Future<bool> start({
    required void Function() onWake,
    required void Function(String error) onError,
  }) async {
    await _teardownSession();
    try {
      // Resolve the model without blocking cook-mode entry on a 40 MB download.
      if (_modelPath == null) {
        final loader = ModelLoader();
        if (!await loader.isModelAlreadyLoaded(_modelName)) {
          // Fetch in the background; this session uses tap-to-talk.
          unawaited(loader.loadFromNetwork(_modelUrl).catchError((Object e) {
            onError('$e');
            return '';
          }));
          return false;
        }
        _modelPath = await loader.modelPath(_modelName);
      }

      final vosk = VoskFlutterPlugin.instance();
      final model = _model ??= await vosk.createModel(_modelPath!);
      // Constrain recognition to the wake phrases (+ [unk]) — a focused spotter
      // is faster and far more accurate than open-ended ASR for this.
      final recognizer = await vosk.createRecognizer(
        model: model,
        sampleRate: _sampleRate,
        grammar: [..._wakePhrases, '[unk]'],
      );
      _recognizer = recognizer;
      final service = await vosk.initSpeechService(recognizer);
      _speechService = service;
      _onWake = onWake;
      _partialSub = service.onPartial().listen(_check);
      _resultSub = service.onResult().listen(_check);
      await service.start(onRecognitionError: (dynamic e) => onError('$e'));
      return true;
    } catch (e) {
      onError('$e');
      await _teardownSession();
      return false;
    }
  }

  void _check(String json) {
    String text;
    try {
      final decoded = jsonDecode(json);
      text = decoded is Map
          ? (decoded['partial'] ?? decoded['text'] ?? '').toString()
          : '';
    } catch (_) {
      return;
    }
    text = text.toLowerCase();
    if (text.isEmpty) return;
    if (_wakePhrases.any(text.contains)) {
      final fire = _onWake;
      _onWake = null; // fire once; the cooking provider stops + restarts us
      fire?.call();
    }
  }

  @override
  Future<void> stop() => _teardownSession();

  Future<void> _teardownSession() async {
    _onWake = null;
    await _partialSub?.cancel();
    await _resultSub?.cancel();
    _partialSub = null;
    _resultSub = null;
    try {
      await _speechService?.dispose();
    } catch (_) {
      // Best-effort teardown.
    }
    _speechService = null;
    try {
      await _recognizer?.dispose();
    } catch (_) {
      // Best-effort teardown.
    }
    _recognizer = null;
    // The loaded model + cached path are kept; reloading is expensive.
  }
}
