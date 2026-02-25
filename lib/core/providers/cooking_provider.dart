import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/recipe.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../network/websocket_client.dart';
import 'recipe_provider.dart';

class CookingState {
  const CookingState({
    this.recipe,
    this.currentStep = 0,
    this.totalSteps = 0,
    this.isListening = false,
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
  final apiClient = ref.watch(apiClientProvider);
  final notifier = CookingNotifier(
    wsClient: wsClient,
    apiClient: apiClient,
  );
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class CookingNotifier extends StateNotifier<CookingState> {
  CookingNotifier({
    required WebSocketClient wsClient,
    required ApiClient apiClient,
  })  : _wsClient = wsClient,
        _apiClient = apiClient,
        super(const CookingState());

  final WebSocketClient _wsClient;
  final ApiClient _apiClient;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<WebSocketConnectionState>? _stateSubscription;

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

  void _handleWsMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    switch (type) {
      case 'chat_response':
        final text = message['text'] as String? ?? '';
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
      case 'step_update':
        final step = message['step'] as int?;
        if (step != null) {
          state = state.copyWith(currentStep: step);
        }
      case 'voice_command':
        _handleVoiceCommand(message['command'] as String? ?? '');
    }
  }

  void _handleVoiceCommand(String command) {
    final lower = command.toLowerCase().trim();
    if (lower == 'next' || lower == 'next step') {
      nextStep();
    } else if (lower == 'previous' || lower == 'back' || lower == 'previous step') {
      previousStep();
    } else if (lower.startsWith('go to step')) {
      final num = int.tryParse(lower.replaceAll(RegExp(r'[^0-9]'), ''));
      if (num != null) goToStep(num - 1);
    }
  }

  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _wsClient.send({
        'type': 'step_change',
        'step': state.currentStep,
      });
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
      _wsClient.send({
        'type': 'step_change',
        'step': state.currentStep,
      });
    }
  }

  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
      _wsClient.send({
        'type': 'step_change',
        'step': step,
      });
    }
  }

  void toggleChat() {
    state = state.copyWith(isChatOpen: !state.isChatOpen);
  }

  void toggleListening() {
    state = state.copyWith(isListening: !state.isListening);
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
      'text': text,
      'current_step': state.currentStep,
    });
  }

  void applyEphemeralEdit(int step, String newInstruction) {
    final edits = Map<int, String>.from(state.ephemeralEdits);
    edits[step] = newInstruction;
    state = state.copyWith(ephemeralEdits: edits);
  }

  Future<void> endSession() async {
    await _wsClient.disconnect();
    _messageSubscription?.cancel();
    _stateSubscription?.cancel();
  }

  void dispose() {
    endSession();
  }
}
