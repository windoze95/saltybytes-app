import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/websocket_client.dart';
import '../voice/speech_service.dart';

/// Hands-free voice phases for cooking mode.
///
/// [passive]: the app listens on-device for the "hey salty" wake phrase and
/// sends nothing to the server. [active]: a wake word was heard, so utterances
/// are captured and sent as commands; after a stretch of silence or irrelevant
/// speech the session relaxes back to [passive]. [off]: the mic is muted.
enum HandsFreePhase { off, passive, active }

/// Default wake cue: a short haptic tap plus the system click sound.
void _defaultWakeSignal() {
  HapticFeedback.mediumImpact();
  SystemSound.play(SystemSoundType.click);
}

class CookingState {
  const CookingState({
    this.recipe,
    this.currentStep = 0,
    this.totalSteps = 0,
    this.isListening = false,
    this.voiceAvailable = true,
    this.voiceTranscript = '',
    this.handsFreePhase = HandsFreePhase.off,
    this.isChatOpen = false,
    this.chatMessages = const [],
    this.wsState = WebSocketConnectionState.disconnected,
    this.ephemeralEdits = const {},
    this.error,
  });

  final Recipe? recipe;
  final int currentStep;
  final int totalSteps;
  final bool isListening;

  /// False when speech recognition is unavailable or mic permission denied.
  final bool voiceAvailable;

  /// Partial transcript streamed from on-device STT while listening.
  final String voiceTranscript;

  /// Current hands-free voice phase (off / passive wake-word / active command).
  final HandsFreePhase handsFreePhase;
  final bool isChatOpen;
  final List<ChatMessage> chatMessages;
  final WebSocketConnectionState wsState;
  final Map<int, String> ephemeralEdits;
  final String? error;

  String get currentInstruction {
    if (recipe == null || recipe!.instructions.isEmpty) return '';
    final step = currentStep.clamp(0, recipe!.instructions.length - 1);
    return ephemeralEdits[step] ?? recipe!.instructions[step];
  }

  bool get isFirstStep => currentStep == 0;
  bool get isLastStep => currentStep >= totalSteps - 1;

  CookingState copyWith({
    Recipe? recipe,
    int? currentStep,
    int? totalSteps,
    bool? isListening,
    bool? voiceAvailable,
    String? voiceTranscript,
    HandsFreePhase? handsFreePhase,
    bool? isChatOpen,
    List<ChatMessage>? chatMessages,
    WebSocketConnectionState? wsState,
    Map<int, String>? ephemeralEdits,
    String? error,
  }) {
    return CookingState(
      recipe: recipe ?? this.recipe,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isListening: isListening ?? this.isListening,
      voiceAvailable: voiceAvailable ?? this.voiceAvailable,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      handsFreePhase: handsFreePhase ?? this.handsFreePhase,
      isChatOpen: isChatOpen ?? this.isChatOpen,
      chatMessages: chatMessages ?? this.chatMessages,
      wsState: wsState ?? this.wsState,
      ephemeralEdits: ephemeralEdits ?? this.ephemeralEdits,
      error: error,
    );
  }
}

class ChatMessage {
  const ChatMessage({
    required this.text,
    required this.isUser,
    this.timestamp,
  });

  final String text;
  final bool isUser;
  final DateTime? timestamp;
}

final cookingProvider =
    StateNotifierProvider.autoDispose<CookingNotifier, CookingState>((ref) {
  final wsClient = ref.watch(websocketClientProvider);
  final speechService = ref.watch(speechServiceProvider);
  return CookingNotifier(
    wsClient: wsClient,
    speechService: speechService,
  );
});

class CookingNotifier extends StateNotifier<CookingState> {
  CookingNotifier({
    required WebSocketClient wsClient,
    required SpeechService speechService,
    Duration wakeWindow = const Duration(seconds: 15),
    int maxIgnores = 2,
    Duration restartDelay = const Duration(milliseconds: 250),
    void Function()? onWakeSignal,
  })  : _wsClient = wsClient,
        _speechService = speechService,
        _wakeWindow = wakeWindow,
        _maxIgnores = maxIgnores,
        _restartDelay = restartDelay,
        _onWakeSignal = onWakeSignal ?? _defaultWakeSignal,
        super(const CookingState());

  final WebSocketClient _wsClient;
  final SpeechService _speechService;

  /// How long the active command window stays open before relaxing back to
  /// passive wake-word listening (reset by each relevant command).
  final Duration _wakeWindow;

  /// Consecutive ignored/incoherent results that collapse active → passive.
  final int _maxIgnores;

  /// Delay before re-arming the recognizer after it ends a session, so the
  /// always-listening loop doesn't tight-loop the platform recognizer.
  final Duration _restartDelay;
  final void Function() _onWakeSignal;

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<WebSocketConnectionState>? _stateSubscription;
  Timer? _wakeWindowTimer;
  Timer? _restartTimer;
  int _incoherentCount = 0;
  bool _disposed = false;

  /// Wake phrases matched locally against finalized transcripts. Kept liberal
  /// to absorb common mishearings of "hey salty".
  static const _wakePhrases = [
    'hey salty',
    'hey saltie',
    'hey saltee',
    'hey salt',
    'hey sally',
    'hi salty',
    'okay salty',
    'ok salty',
  ];

  Future<void> startSession(Recipe recipe) async {
    state = state.copyWith(
      recipe: recipe,
      currentStep: 0,
      totalSteps: recipe.instructions.length,
      chatMessages: [],
      ephemeralEdits: {},
    );

    _stateSubscription = _wsClient.connectionState.listen((wsState) {
      if (mounted) {
        state = state.copyWith(wsState: wsState);
      }
    });

    _messageSubscription = _wsClient.messages.listen(_handleWsMessage);

    await _wsClient.connect(recipe.id);

    // Cook mode is hands-free by default: start listening for the wake word
    // right away when the mic is available, and fall back silently to the mic
    // button (tap to enable) when permission isn't granted.
    await _enableHandsFree(silentOnDenied: true);
  }

  /// Handles incoming `{"type": ..., "payload": {...}}` envelopes (contract
  /// C9). Unknown types and malformed payloads are ignored.
  void _handleWsMessage(Map<String, dynamic> message) {
    if (!mounted) return;

    final type = message['type'] as String?;
    final rawPayload = message['payload'];
    final payload =
        rawPayload is Map<String, dynamic> ? rawPayload : <String, dynamic>{};

    switch (type) {
      case 'connected':
        state = state.copyWith(wsState: WebSocketConnectionState.connected);
      case 'chat_response':
        final text = payload['message'] as String? ?? '';
        if (text.isEmpty) return;
        state = state.copyWith(
          chatMessages: [
            ...state.chatMessages,
            ChatMessage(
              text: text,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          ],
        );
      case 'voice_intent':
        _handleVoiceIntent(payload);
      case 'scroll_command':
        _handleScrollCommand(payload);
      case 'navigate_command':
        _handleNavigateCommand(payload);
      case 'pong':
        // Liveness only; handled by the WebSocket client.
        break;
      case 'error':
        final msg = payload['message'] as String? ?? 'Something went wrong';
        developer.log('Cooking WS error: $msg', name: 'Cooking');
        state = state.copyWith(error: msg);
    }
  }

  /// A `question` intent is answered with a follow-up chat_response, so echo
  /// the recognized question into the chat and open it for the answer. The
  /// classified type also drives the hands-free auto-stop: relevant intents
  /// keep the active window open, while `ignore` counts toward relaxing back
  /// to passive wake-word listening.
  void _handleVoiceIntent(Map<String, dynamic> payload) {
    final intentType = payload['type'] as String? ?? '';
    final text = payload['text'] as String? ?? '';

    if (intentType == 'ignore') {
      _registerIncoherent();
    } else if (intentType.isNotEmpty) {
      _onRelevantCommand();
    }

    if (intentType == 'question' && text.isNotEmpty) {
      state = state.copyWith(
        isChatOpen: true,
        chatMessages: [
          ...state.chatMessages,
          ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
        ],
      );
    }
  }

  /// scroll_command carries either an absolute `step` or a `direction`.
  void _handleScrollCommand(Map<String, dynamic> payload) {
    final step = _asInt(payload['step']);
    if (step != null) {
      goToStep(step);
      return;
    }
    switch (payload['direction'] as String?) {
      case 'up':
        previousStep();
      case 'down':
        nextStep();
    }
  }

  /// navigate_command targets: "ingredients", "instructions", or "step_N"
  /// (1-based). Only step targets have a surface in cooking mode.
  void _handleNavigateCommand(Map<String, dynamic> payload) {
    final target = payload['target'] as String? ?? '';
    if (target.startsWith('step_')) {
      final stepNumber = int.tryParse(target.substring('step_'.length));
      if (stepNumber != null) goToStep(stepNumber - 1);
    }
  }

  /// Numeric values may arrive as int, double, or String — normalize.
  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  void _sendStepChange() {
    _wsClient.send({
      'type': 'step_change',
      'payload': {'step': state.currentStep},
    });
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _sendStepChange();
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      _sendStepChange();
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
      _sendStepChange();
    }
  }

  void toggleChat() {
    state = state.copyWith(isChatOpen: !state.isChatOpen);
  }

  /// Master hands-free switch (the mic button): off → start passive wake-word
  /// listening; otherwise stop entirely (mute).
  Future<void> toggleHandsFree() async {
    if (state.handsFreePhase != HandsFreePhase.off) {
      await _disableHandsFree();
      return;
    }
    await _enableHandsFree(silentOnDenied: false);
  }

  Future<void> _enableHandsFree({required bool silentOnDenied}) async {
    if (state.handsFreePhase != HandsFreePhase.off) return;

    final available = await _speechService.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (!mounted) return;

    if (!available) {
      state = state.copyWith(
        voiceAvailable: false,
        handsFreePhase: HandsFreePhase.off,
        error: silentOnDenied
            ? null
            : 'Voice input is unavailable. Check microphone permissions.',
      );
      return;
    }

    _incoherentCount = 0;
    state = state.copyWith(
      voiceAvailable: true,
      handsFreePhase: HandsFreePhase.passive,
      voiceTranscript: '',
    );
    await _startListening();
  }

  Future<void> _disableHandsFree() async {
    _wakeWindowTimer?.cancel();
    _restartTimer?.cancel();
    _incoherentCount = 0;
    await _speechService.stop();
    if (!mounted) return;
    state = state.copyWith(
      handsFreePhase: HandsFreePhase.off,
      isListening: false,
      voiceTranscript: '',
    );
  }

  /// (Re)arms the recognizer for the always-listening loop.
  Future<void> _startListening() async {
    if (state.handsFreePhase == HandsFreePhase.off) return;
    if (mounted) state = state.copyWith(isListening: true);
    await _speechService.listen(onResult: _onSpeechResult);
  }

  /// The platform recognizer ends each session after silence or its max
  /// duration; re-arm it (after a short delay) to keep listening.
  void _scheduleRestart() {
    if (state.handsFreePhase == HandsFreePhase.off) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(_restartDelay, () {
      if (!mounted || state.handsFreePhase == HandsFreePhase.off) return;
      unawaited(_startListening());
    });
  }

  void _onSpeechResult(String text, bool isFinal) {
    if (!mounted || state.handsFreePhase == HandsFreePhase.off) return;

    if (!isFinal) {
      // Only surface a live transcript once actively capturing a command.
      if (state.handsFreePhase == HandsFreePhase.active) {
        state = state.copyWith(voiceTranscript: text);
      }
      return;
    }

    final transcript = text.trim();
    state = state.copyWith(voiceTranscript: '');

    if (state.handsFreePhase == HandsFreePhase.passive) {
      final command = _wakeRemainder(transcript);
      if (command == null) return; // no wake word — keep listening passively
      _enterActive(immediateCommand: command);
      return;
    }

    // Active phase: the utterance is a command.
    if (transcript.length < 2) {
      _registerIncoherent();
      return;
    }
    _sendVoiceCommand(transcript);
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status != 'done' && status != 'notListening') return;
    if (state.handsFreePhase == HandsFreePhase.off) {
      if (state.isListening) state = state.copyWith(isListening: false);
      return;
    }
    _scheduleRestart();
  }

  void _onSpeechError(String error) {
    if (!mounted) return;
    developer.log('Speech recognition error: $error', name: 'Cooking');
    state = state.copyWith(voiceTranscript: '');
    if (state.handsFreePhase != HandsFreePhase.off) {
      _scheduleRestart();
    } else if (state.isListening) {
      state = state.copyWith(isListening: false);
    }
  }

  /// Returns the command following a wake phrase (possibly empty) when the
  /// transcript contains one, or null when it has no wake word.
  String? _wakeRemainder(String transcript) {
    final lower = transcript.toLowerCase();
    for (final phrase in _wakePhrases) {
      final idx = lower.indexOf(phrase);
      if (idx >= 0) {
        return transcript.substring(idx + phrase.length).trim();
      }
    }
    return null;
  }

  void _enterActive({String immediateCommand = ''}) {
    _incoherentCount = 0;
    state = state.copyWith(handsFreePhase: HandsFreePhase.active);
    _onWakeSignal();
    _resetWakeWindow();
    if (immediateCommand.length >= 2) {
      _sendVoiceCommand(immediateCommand);
    }
  }

  void _sendVoiceCommand(String transcript) {
    _wsClient.send({
      'type': 'voice_transcript',
      'payload': {'transcript': transcript},
    });
  }

  /// A relevant intent keeps the active window open and clears the ignore tally.
  void _onRelevantCommand() {
    if (state.handsFreePhase != HandsFreePhase.active) return;
    _incoherentCount = 0;
    _resetWakeWindow();
  }

  void _registerIncoherent() {
    if (state.handsFreePhase != HandsFreePhase.active) return;
    _incoherentCount++;
    if (_incoherentCount >= _maxIgnores) {
      _revertToPassive();
    }
  }

  void _resetWakeWindow() {
    _wakeWindowTimer?.cancel();
    _wakeWindowTimer = Timer(_wakeWindow, () {
      if (mounted) _revertToPassive();
    });
  }

  void _revertToPassive() {
    if (state.handsFreePhase == HandsFreePhase.off) return;
    _wakeWindowTimer?.cancel();
    _incoherentCount = 0;
    state = state.copyWith(
      handsFreePhase: HandsFreePhase.passive,
      voiceTranscript: '',
    );
  }

  void sendChatMessage(String text) {
    if (text.trim().isEmpty) return;

    state = state.copyWith(
      chatMessages: [
        ...state.chatMessages,
        ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      ],
    );

    _wsClient.send({
      'type': 'chat_message',
      'payload': {'message': text},
    });
  }

  void applyEphemeralEdit(int step, String newInstruction) {
    final edits = Map<int, String>.from(state.ephemeralEdits);
    edits[step] = newInstruction;
    state = state.copyWith(ephemeralEdits: edits);
  }

  Future<void> endSession() async {
    _wakeWindowTimer?.cancel();
    _restartTimer?.cancel();
    _messageSubscription?.cancel();
    _stateSubscription?.cancel();
    await _speechService.stop();
    await _wsClient.disconnect();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(endSession());
    super.dispose();
  }
}
