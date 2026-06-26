import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/websocket_client.dart';
import '../voice/speech_service.dart';
import '../voice/wake_word_service.dart';

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
  final wakeWord = ref.watch(wakeWordServiceProvider);
  return CookingNotifier(
    wsClient: wsClient,
    speechService: speechService,
    wakeWord: wakeWord,
  );
});

class CookingNotifier extends StateNotifier<CookingState> {
  CookingNotifier({
    required WebSocketClient wsClient,
    required SpeechService speechService,
    required WakeWordService wakeWord,
    Duration wakeWindow = const Duration(seconds: 15),
    int maxIgnores = 2,
    Duration restartDelay = const Duration(milliseconds: 250),
    void Function()? onWakeSignal,
  })  : _wsClient = wsClient,
        _speechService = speechService,
        _wakeWord = wakeWord,
        _wakeWindow = wakeWindow,
        _maxIgnores = maxIgnores,
        _restartDelay = restartDelay,
        _onWakeSignal = onWakeSignal ?? _defaultWakeSignal,
        super(const CookingState());

  final WebSocketClient _wsClient;
  final SpeechService _speechService;
  final WakeWordService _wakeWord;

  /// How long the active command window stays open before relaxing back to
  /// passive wake-word listening (reset by each relevant command).
  final Duration _wakeWindow;

  /// Consecutive ignored/incoherent results that collapse active → passive.
  final int _maxIgnores;

  /// Delay before re-arming the command recognizer between active-phase
  /// captures, so the loop doesn't tight-loop the platform recognizer.
  final Duration _restartDelay;
  final void Function() _onWakeSignal;

  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<WebSocketConnectionState>? _stateSubscription;
  Timer? _wakeWindowTimer;
  Timer? _restartTimer;
  int _incoherentCount = 0;

  /// True once the wake-word engine has started this session; when false,
  /// hands-free uses manual tap-to-talk instead of passive wake listening.
  bool _wakeAvailable = false;
  bool _disposed = false;

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

    // Cook mode is hands-free by default: start the wake-word engine right
    // away when the mic is available. Without a wake engine (or permission) it
    // stays idle and the mic button does a manual tap-to-talk.
    await _enableHandsFree(auto: true);
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

  /// Master hands-free switch (the mic button): off → start listening (passive
  /// wake word when configured, otherwise a manual tap-to-talk capture);
  /// otherwise stop entirely (mute).
  Future<void> toggleHandsFree() async {
    if (state.handsFreePhase != HandsFreePhase.off) {
      await _disableHandsFree();
      return;
    }
    await _enableHandsFree(auto: false);
  }

  /// Brings up hands-free. [auto] marks the automatic start at cook-mode entry,
  /// which never begins recording on its own when no wake word is configured
  /// (the user taps the mic to talk instead).
  Future<void> _enableHandsFree({required bool auto}) async {
    if (state.handsFreePhase != HandsFreePhase.off) return;

    // speech_to_text powers the active command phase; initializing it also
    // secures the mic/speech permission the wake engine needs.
    final speechReady = await _speechService.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (!mounted) return;
    if (!speechReady) {
      state = state.copyWith(
        voiceAvailable: false,
        handsFreePhase: HandsFreePhase.off,
        error: auto
            ? null
            : 'Voice input is unavailable. Check microphone permissions.',
      );
      return;
    }

    _incoherentCount = 0;
    _wakeAvailable = await _wakeWord.start(
      onWake: _onWakeWordDetected,
      onError: _onWakeError,
    );
    if (!mounted) return;

    if (_wakeAvailable) {
      state = state.copyWith(
        voiceAvailable: true,
        handsFreePhase: HandsFreePhase.passive,
        voiceTranscript: '',
      );
      return;
    }

    // No wake-word engine configured: the automatic start stays idle (tap the
    // mic to talk), while an explicit tap captures a command right away.
    if (auto) {
      state = state.copyWith(
        voiceAvailable: true,
        handsFreePhase: HandsFreePhase.off,
      );
      return;
    }
    await _enterActive();
  }

  Future<void> _disableHandsFree() async {
    _wakeWindowTimer?.cancel();
    _restartTimer?.cancel();
    _incoherentCount = 0;
    await _wakeWord.stop();
    await _speechService.stop();
    if (!mounted) return;
    state = state.copyWith(
      handsFreePhase: HandsFreePhase.off,
      isListening: false,
      voiceTranscript: '',
    );
  }

  /// The wake engine fired: hand the mic from the wake engine to the command
  /// recognizer and start capturing.
  void _onWakeWordDetected() {
    if (!mounted || state.handsFreePhase != HandsFreePhase.passive) return;
    unawaited(_enterActive());
  }

  void _onWakeError(String error) {
    developer.log('Wake-word error: $error', name: 'Cooking');
  }

  Future<void> _enterActive() async {
    await _wakeWord.stop();
    if (!mounted) return;
    _incoherentCount = 0;
    state = state.copyWith(handsFreePhase: HandsFreePhase.active);
    _onWakeSignal();
    _resetWakeWindow();
    await _startListening();
  }

  /// (Re)arms the command recognizer for the active capture loop.
  Future<void> _startListening() async {
    if (state.handsFreePhase != HandsFreePhase.active) return;
    if (mounted) state = state.copyWith(isListening: true);
    await _speechService.listen(onResult: _onSpeechResult);
  }

  /// speech_to_text ends each session after silence or its max duration; while
  /// active, re-arm it (after a short delay) so follow-up commands are caught.
  void _scheduleRestart() {
    if (state.handsFreePhase != HandsFreePhase.active) return;
    _restartTimer?.cancel();
    _restartTimer = Timer(_restartDelay, () {
      if (!mounted || state.handsFreePhase != HandsFreePhase.active) return;
      unawaited(_startListening());
    });
  }

  void _onSpeechResult(String text, bool isFinal) {
    if (!mounted || state.handsFreePhase != HandsFreePhase.active) return;

    if (!isFinal) {
      state = state.copyWith(voiceTranscript: text);
      return;
    }

    final transcript = text.trim();
    state = state.copyWith(voiceTranscript: '');
    if (transcript.length < 2) {
      _registerIncoherent();
      return;
    }
    _sendVoiceCommand(transcript);
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    if (status != 'done' && status != 'notListening') return;
    if (state.handsFreePhase == HandsFreePhase.active) {
      _scheduleRestart();
    } else if (state.isListening) {
      state = state.copyWith(isListening: false);
    }
  }

  void _onSpeechError(String error) {
    if (!mounted) return;
    developer.log('Speech recognition error: $error', name: 'Cooking');
    state = state.copyWith(voiceTranscript: '');
    if (state.handsFreePhase == HandsFreePhase.active) {
      _scheduleRestart();
    } else if (state.isListening) {
      state = state.copyWith(isListening: false);
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
      unawaited(_relax());
    }
  }

  void _resetWakeWindow() {
    _wakeWindowTimer?.cancel();
    _wakeWindowTimer = Timer(_wakeWindow, () {
      if (mounted) unawaited(_relax());
    });
  }

  /// Ends the active command window: back to passive wake-word listening when a
  /// wake engine is configured, otherwise fully idle.
  Future<void> _relax() async {
    if (state.handsFreePhase != HandsFreePhase.active) return;
    _wakeWindowTimer?.cancel();
    _restartTimer?.cancel();
    _incoherentCount = 0;
    await _speechService.stop();
    if (!mounted) return;

    if (_wakeAvailable &&
        await _wakeWord.start(
          onWake: _onWakeWordDetected,
          onError: _onWakeError,
        )) {
      if (!mounted) return;
      state = state.copyWith(
        handsFreePhase: HandsFreePhase.passive,
        isListening: false,
        voiceTranscript: '',
      );
      return;
    }

    _wakeAvailable = false;
    state = state.copyWith(
      handsFreePhase: HandsFreePhase.off,
      isListening: false,
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
    await _wakeWord.stop();
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
