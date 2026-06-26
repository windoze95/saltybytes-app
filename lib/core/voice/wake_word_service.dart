import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:porcupine_flutter/porcupine_error.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';

/// Provides the on-device wake-word engine used by cooking mode.
final wakeWordServiceProvider = Provider<WakeWordService>((ref) {
  return PorcupineWakeWordService();
});

/// On-device "hey salty" wake-word detection. A purpose-built engine
/// (Picovoice Porcupine) handles always-listening detection far more reliably
/// and with much lower battery cost than looping general speech-to-text.
abstract class WakeWordService {
  /// Whether the engine is configured (access key + a keyword model present).
  /// When false, hands-free falls back to manual tap-to-talk.
  bool get isConfigured;

  /// Starts always-listening wake-word detection. [onWake] fires on each
  /// detection. Returns false when it could not start (not configured, mic
  /// permission denied, or an engine error).
  Future<bool> start({
    required void Function() onWake,
    required void Function(String error) onError,
  });

  /// Stops detection and releases the microphone. Safe to call when stopped.
  Future<void> stop();
}

/// [WakeWordService] backed by Picovoice Porcupine.
///
/// Setup (see assets/wake/README.md): obtain a Picovoice AccessKey, train a
/// "Hey Salty" keyword on the Picovoice Console, and drop the per-platform
/// `.ppn` models into assets/wake/. The access key is supplied at build time
/// via `--dart-define=PICOVOICE_ACCESS_KEY=...`. Until both are present the
/// service reports `isConfigured == false` and hands-free uses tap-to-talk.
class PorcupineWakeWordService implements WakeWordService {
  PorcupineWakeWordService({String? accessKey, List<String>? keywordAssetPaths})
      : _accessKey =
            accessKey ?? const String.fromEnvironment('PICOVOICE_ACCESS_KEY'),
        _keywordAssetPaths = keywordAssetPaths ?? _defaultKeywordAssets();

  final String _accessKey;
  final List<String> _keywordAssetPaths;
  PorcupineManager? _manager;

  static List<String> _defaultKeywordAssets() {
    if (Platform.isIOS) return const ['assets/wake/hey_salty_ios.ppn'];
    if (Platform.isAndroid) return const ['assets/wake/hey_salty_android.ppn'];
    return const [];
  }

  @override
  bool get isConfigured =>
      _accessKey.isNotEmpty && _keywordAssetPaths.isNotEmpty;

  @override
  Future<bool> start({
    required void Function() onWake,
    required void Function(String error) onError,
  }) async {
    if (!isConfigured) return false;
    try {
      _manager = await PorcupineManager.fromKeywordPaths(
        _accessKey,
        _keywordAssetPaths,
        (_) => onWake(),
        errorCallback: (e) => onError(e.message ?? 'wake-word error'),
      );
      await _manager!.start();
      return true;
    } on PorcupineException catch (e) {
      onError(e.message ?? 'wake-word engine failed to start');
      await _dispose();
      return false;
    } catch (e) {
      onError('$e');
      await _dispose();
      return false;
    }
  }

  @override
  Future<void> stop() => _dispose();

  Future<void> _dispose() async {
    try {
      await _manager?.stop();
      await _manager?.delete();
    } catch (_) {
      // Best-effort teardown.
    }
    _manager = null;
  }
}
