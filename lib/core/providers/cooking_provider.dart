import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/websocket_client.dart';
import '../voice/speech_service.dart';

class CookingState {
  const CookingState({
    this.recipe,
    this.currentStep = 0,
    this.totalSteps = 0,
    this.isListening = false,
    this.voiceAvailable = true,
    this.voiceTranscript = '',
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
  })  : _wsClient = wsClient,
        _speechService = speechService,
        super(const CookingState());

  final WebSocketClient _wsClient;
  final SpeechService _speechService;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<WebSocketConnectionState>? _stateSubscription;
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
  /// the recognized question into the chat and open it for the answer.
  void _handleVoiceIntent(Map<String, dynamic> payload) {
    final intentType = payload['type'] as String? ?? '';
    final text = payload['text'] as String? ?? '';
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

  /// Starts or stops on-device speech capture. Partial transcripts stream
  /// into [CookingState.voiceTranscript]; the final transcript is sent to
  /// the server as a voice_transcript envelope.
  Future<void> toggleListening() async {
    if (state.isListening) {
      await _speechService.stop();
      if (mounted) {
        state = state.copyWith(isListening: false);
      }
      return;
    }

    final available = await _speechService.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (!mounted) return;

    if (!available) {
      state = state.copyWith(
        voiceAvailable: false,
        error: 'Voice input is unavailable. Check microphone permissions.',
      );
      return;
    }

    state = state.copyWith(
      isListening: true,
      voiceAvailable: true,
      voiceTranscript: '',
    );
    await _speechService.listen(onResult: _onSpeechResult);
  }

  void _onSpeechResult(String text, bool isFinal) {
    if (!mounted) return;

    if (!isFinal) {
      state = state.copyWith(voiceTranscript: text);
      return;
    }

    state = state.copyWith(isListening: false, voiceTranscript: '');
    final transcript = text.trim();
    if (transcript.isEmpty) return;
    _wsClient.send({
      'type': 'voice_transcript',
      'payload': {'transcript': transcript},
    });
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    // The recognizer stops itself after silence or when listenFor expires.
    if ((status == 'done' || status == 'notListening') && state.isListening) {
      state = state.copyWith(isListening: false);
    }
  }

  void _onSpeechError(String error) {
    if (!mounted) return;
    developer.log('Speech recognition error: $error', name: 'Cooking');
    state = state.copyWith(isListening: false, voiceTranscript: '');
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
