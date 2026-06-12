import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:saltybytes_app/core/network/websocket_client.dart';
import 'package:saltybytes_app/core/providers/cooking_provider.dart';
import 'package:saltybytes_app/core/voice/speech_service.dart';
import 'package:saltybytes_app/models/recipe.dart';

import '../helpers/fixtures.dart';

/// Fake WebSocket client that records outgoing messages and lets tests
/// emit incoming server messages onto the stream.
class _FakeWebSocketClient implements WebSocketClient {
  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  final List<Map<String, dynamic>> sent = [];
  String? connectedRecipeId;
  bool disconnectCalled = false;

  @override
  Stream<WebSocketConnectionState> get connectionState =>
      _stateController.stream;

  @override
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  @override
  WebSocketConnectionState get currentState =>
      WebSocketConnectionState.connected;

  @override
  Future<void> connect(String recipeId) async {
    connectedRecipeId = recipeId;
  }

  @override
  void send(Map<String, dynamic> message) => sent.add(message);

  @override
  Future<void> disconnect() async {
    disconnectCalled = true;
  }

  @override
  void dispose() {
    _stateController.close();
    _messageController.close();
  }

  /// Simulates a message arriving from the server.
  void emit(Map<String, dynamic> message) => _messageController.add(message);

  void emitState(WebSocketConnectionState state) =>
      _stateController.add(state);
}

/// Fake speech service exposing the registered callbacks so tests can
/// drive partial/final recognition results and status changes.
class _FakeSpeechService implements SpeechService {
  bool available = true;
  bool initializeCalled = false;
  bool listenCalled = false;
  bool stopCalled = false;
  bool _listening = false;

  void Function(String text, bool isFinal)? resultListener;
  void Function(String status)? statusListener;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    initializeCalled = true;
    statusListener = onStatus;
    return available;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    listenCalled = true;
    resultListener = onResult;
    _listening = true;
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    _listening = false;
  }

  @override
  bool get isListening => _listening;
}

void main() {
  late _FakeWebSocketClient ws;
  late _FakeSpeechService speech;
  late ProviderContainer container;
  late CookingNotifier notifier;

  final recipe = Recipe.fromJson(testRecipeJson());

  CookingState readState() => container.read(cookingProvider);

  setUp(() async {
    ws = _FakeWebSocketClient();
    speech = _FakeSpeechService();
    container = ProviderContainer(overrides: [
      websocketClientProvider.overrideWithValue(ws),
      speechServiceProvider.overrideWithValue(speech),
    ]);
    addTearDown(container.dispose);

    // Keep the autoDispose provider alive for the duration of the test.
    container.listen(cookingProvider, (_, __) {});
    notifier = container.read(cookingProvider.notifier);
    await notifier.startSession(recipe);
  });

  group('session start', () {
    test('connects with the recipe id and resets state', () {
      expect(ws.connectedRecipeId, recipe.id);
      final state = readState();
      expect(state.currentStep, 0);
      // The fixture recipe has 4 instructions.
      expect(state.totalSteps, 4);
      expect(state.chatMessages, isEmpty);
    });
  });

  group('outgoing envelopes', () {
    test('sendChatMessage sends chat_message envelope and appends user '
        'message', () {
      notifier.sendChatMessage('How long should I knead?');

      expect(ws.sent, [
        {
          'type': 'chat_message',
          'payload': {'message': 'How long should I knead?'},
        },
      ]);
      final state = readState();
      expect(state.chatMessages, hasLength(1));
      expect(state.chatMessages.single.isUser, true);
      expect(state.chatMessages.single.text, 'How long should I knead?');
    });

    test('sendChatMessage ignores blank text', () {
      notifier.sendChatMessage('   ');
      expect(ws.sent, isEmpty);
      expect(readState().chatMessages, isEmpty);
    });

    test('nextStep advances and sends step_change envelope', () {
      notifier.nextStep();

      expect(readState().currentStep, 1);
      expect(ws.sent.single, {
        'type': 'step_change',
        'payload': {'step': 1},
      });
    });

    test('previousStep at the first step sends nothing', () {
      notifier.previousStep();
      expect(readState().currentStep, 0);
      expect(ws.sent, isEmpty);
    });

    test('goToStep sends the target step; out-of-range is ignored', () {
      notifier.goToStep(3);
      expect(readState().currentStep, 3);
      expect(ws.sent.single, {
        'type': 'step_change',
        'payload': {'step': 3},
      });

      notifier.goToStep(99);
      notifier.goToStep(-1);
      expect(readState().currentStep, 3);
      expect(ws.sent, hasLength(1));
    });
  });

  group('voice capture', () {
    test('toggleListening starts STT and streams partial transcripts', () async {
      await notifier.toggleListening();

      expect(speech.initializeCalled, true);
      expect(speech.listenCalled, true);
      expect(readState().isListening, true);

      speech.resultListener!('set a tim', false);
      expect(readState().voiceTranscript, 'set a tim');
      expect(readState().isListening, true);
      expect(ws.sent, isEmpty);
    });

    test('final result sends voice_transcript envelope and stops listening',
        () async {
      await notifier.toggleListening();

      speech.resultListener!('go to the next step', true);

      final state = readState();
      expect(state.isListening, false);
      expect(state.voiceTranscript, '');
      expect(ws.sent.single, {
        'type': 'voice_transcript',
        'payload': {'transcript': 'go to the next step'},
      });
    });

    test('empty final transcript is not sent', () async {
      await notifier.toggleListening();
      speech.resultListener!('   ', true);
      expect(ws.sent, isEmpty);
    });

    test('toggleListening while listening stops STT', () async {
      await notifier.toggleListening();
      await notifier.toggleListening();

      expect(speech.stopCalled, true);
      expect(readState().isListening, false);
      expect(ws.sent, isEmpty);
    });

    test('unavailable speech marks voiceAvailable false with an error',
        () async {
      speech.available = false;

      await notifier.toggleListening();

      final state = readState();
      expect(state.voiceAvailable, false);
      expect(state.isListening, false);
      expect(state.error, isNotNull);
      expect(speech.listenCalled, false);
    });

    test('done status resets the listening flag', () async {
      await notifier.toggleListening();
      expect(readState().isListening, true);

      speech.statusListener!('done');
      expect(readState().isListening, false);
    });
  });

  group('incoming messages', () {
    test('chat_response appends an assistant message', () async {
      ws.emit({
        'type': 'chat_response',
        'payload': {'message': 'Knead for about 10 minutes.'},
      });
      await pumpEventQueue();

      final state = readState();
      expect(state.chatMessages, hasLength(1));
      expect(state.chatMessages.single.isUser, false);
      expect(state.chatMessages.single.text, 'Knead for about 10 minutes.');
    });

    test('chat_response with missing payload is ignored', () async {
      ws.emit({'type': 'chat_response'});
      await pumpEventQueue();

      expect(readState().chatMessages, isEmpty);
    });

    test('connected sets the ws state to connected', () async {
      expect(readState().wsState, WebSocketConnectionState.disconnected);

      ws.emit({
        'type': 'connected',
        'payload': {'recipe_id': recipe.id, 'user_id': 1},
      });
      await pumpEventQueue();

      expect(readState().wsState, WebSocketConnectionState.connected);
    });

    test('scroll_command with an int step jumps to that step and echoes '
        'step_change', () async {
      ws.emit({
        'type': 'scroll_command',
        'payload': {'step': 2},
      });
      await pumpEventQueue();

      expect(readState().currentStep, 2);
      expect(ws.sent.single, {
        'type': 'step_change',
        'payload': {'step': 2},
      });
    });

    test('scroll_command tolerates a String step', () async {
      ws.emit({
        'type': 'scroll_command',
        'payload': {'step': '2'},
      });
      await pumpEventQueue();

      expect(readState().currentStep, 2);
    });

    test('scroll_command direction down/up moves one step', () async {
      ws.emit({
        'type': 'scroll_command',
        'payload': {'direction': 'down', 'amount': 'small'},
      });
      await pumpEventQueue();
      expect(readState().currentStep, 1);

      ws.emit({
        'type': 'scroll_command',
        'payload': {'direction': 'up', 'amount': 'small'},
      });
      await pumpEventQueue();
      expect(readState().currentStep, 0);

      // 'up' at the first step stays clamped at 0.
      ws.emit({
        'type': 'scroll_command',
        'payload': {'direction': 'up'},
      });
      await pumpEventQueue();
      expect(readState().currentStep, 0);
    });

    test('navigate_command step_N targets the 1-based step', () async {
      ws.emit({
        'type': 'navigate_command',
        'payload': {'target': 'step_3'},
      });
      await pumpEventQueue();

      expect(readState().currentStep, 2);
    });

    test('navigate_command with a non-step target is ignored', () async {
      ws.emit({
        'type': 'navigate_command',
        'payload': {'target': 'ingredients'},
      });
      await pumpEventQueue();

      expect(readState().currentStep, 0);
      expect(ws.sent, isEmpty);
    });

    test('voice_intent question echoes the question and opens chat',
        () async {
      ws.emit({
        'type': 'voice_intent',
        'payload': {'type': 'question', 'text': 'Can I use honey instead?'},
      });
      await pumpEventQueue();

      final state = readState();
      expect(state.isChatOpen, true);
      expect(state.chatMessages.single.isUser, true);
      expect(state.chatMessages.single.text, 'Can I use honey instead?');
    });

    test('non-question voice_intent does not touch chat', () async {
      ws.emit({
        'type': 'voice_intent',
        'payload': {'type': 'scroll_down', 'amount': 'small'},
      });
      await pumpEventQueue();

      expect(readState().isChatOpen, false);
      expect(readState().chatMessages, isEmpty);
    });

    test('error sets state.error', () async {
      ws.emit({
        'type': 'error',
        'payload': {'message': 'failed to get cooking answer'},
      });
      await pumpEventQueue();

      expect(readState().error, 'failed to get cooking answer');
    });

    test('pong and unknown types leave state unchanged', () async {
      final before = readState();

      ws.emit({'type': 'pong', 'payload': <String, dynamic>{}});
      ws.emit({'type': 'totally_unknown', 'payload': <String, dynamic>{}});
      await pumpEventQueue();

      final after = readState();
      expect(identical(before, after), true);
    });
  });

  group('session end', () {
    test('endSession disconnects the socket and stops speech', () async {
      await notifier.endSession();

      expect(ws.disconnectCalled, true);
      expect(speech.stopCalled, true);
    });
  });
}
