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
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

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

  void emitState(WebSocketConnectionState state) => _stateController.add(state);
}

/// Fake speech service exposing the registered callbacks so tests can
/// drive partial/final recognition results and status changes.
class _FakeSpeechService implements SpeechService {
  bool available = true;
  bool initializeCalled = false;
  int listenCount = 0;
  bool stopCalled = false;
  bool _listening = false;

  void Function(String text, bool isFinal)? resultListener;
  void Function(String status)? statusListener;
  void Function(String error)? errorListener;

  @override
  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    initializeCalled = true;
    statusListener = onStatus;
    errorListener = onError;
    return available;
  }

  @override
  Future<void> listen({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    listenCount++;
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
  late int wakeSignals;

  final recipe = Recipe.fromJson(testRecipeJson());

  CookingState readState() => container.read(cookingProvider);

  setUp(() async {
    ws = _FakeWebSocketClient();
    speech = _FakeSpeechService();
    wakeSignals = 0;
    container = ProviderContainer(overrides: [
      websocketClientProvider.overrideWithValue(ws),
      speechServiceProvider.overrideWithValue(speech),
      // Inject a no-op wake cue (no platform haptics in unit tests) and a
      // zero restart delay so the always-listening loop is deterministic.
      cookingProvider.overrideWith((ref) => CookingNotifier(
            wsClient: ws,
            speechService: speech,
            restartDelay: Duration.zero,
            onWakeSignal: () => wakeSignals++,
          )),
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
    test(
        'sendChatMessage sends chat_message envelope and appends user '
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

  group('hands-free voice', () {
    test('session auto-enables passive wake-word listening', () {
      final state = readState();
      expect(state.handsFreePhase, HandsFreePhase.passive);
      expect(state.isListening, true);
      expect(speech.initializeCalled, true);
      expect(speech.listenCount, 1);
      // Passive listening never sends anything to the server.
      expect(ws.sent, isEmpty);
    });

    test('passive ignores speech without the wake word', () {
      speech.resultListener!('add two cups of flour', true);
      expect(readState().handsFreePhase, HandsFreePhase.passive);
      expect(ws.sent, isEmpty);
      expect(wakeSignals, 0);
    });

    test('passive does not surface partial transcripts', () {
      speech.resultListener!('hey s', false);
      expect(readState().voiceTranscript, '');
    });

    test('wake word switches to active and fires the cue', () {
      speech.resultListener!('hey salty', true);
      expect(readState().handsFreePhase, HandsFreePhase.active);
      expect(wakeSignals, 1);
      expect(ws.sent, isEmpty); // no command after the wake word yet
    });

    test('wake word with a trailing command sends it immediately', () {
      speech.resultListener!('hey salty next step', true);
      expect(readState().handsFreePhase, HandsFreePhase.active);
      expect(ws.sent.single, {
        'type': 'voice_transcript',
        'payload': {'transcript': 'next step'},
      });
    });

    test('active utterances are sent as commands; partials stream', () {
      speech.resultListener!('hey salty', true); // -> active
      speech.resultListener!('how long do I kne', false);
      expect(readState().voiceTranscript, 'how long do I kne');

      speech.resultListener!('how long do I knead', true);
      expect(ws.sent.single, {
        'type': 'voice_transcript',
        'payload': {'transcript': 'how long do I knead'},
      });
    });

    test('two ignored intents relax back to passive', () async {
      speech.resultListener!('hey salty', true);
      expect(readState().handsFreePhase, HandsFreePhase.active);

      ws.emit({
        'type': 'voice_intent',
        'payload': {'type': 'ignore'}
      });
      await pumpEventQueue();
      expect(readState().handsFreePhase, HandsFreePhase.active); // 1st ignore

      ws.emit({
        'type': 'voice_intent',
        'payload': {'type': 'ignore'}
      });
      await pumpEventQueue();
      expect(
          readState().handsFreePhase, HandsFreePhase.passive); // 2nd -> revert
    });

    test('a relevant intent resets the ignore tally', () async {
      speech.resultListener!('hey salty', true);

      ws.emit({
        'type': 'voice_intent',
        'payload': {'type': 'ignore'}
      });
      await pumpEventQueue();
      ws.emit({
        'type': 'voice_intent',
        'payload': {'type': 'scroll_down'}
      });
      await pumpEventQueue();
      ws.emit({
        'type': 'voice_intent',
        'payload': {'type': 'ignore'}
      });
      await pumpEventQueue();

      // The relevant intent reset the tally, so one more ignore is still active.
      expect(readState().handsFreePhase, HandsFreePhase.active);
    });

    test('the recognizer re-arms after it ends (always-listening loop)',
        () async {
      expect(speech.listenCount, 1);
      speech.statusListener!('done');
      await pumpEventQueue();
      expect(speech.listenCount, 2);
      expect(readState().handsFreePhase, HandsFreePhase.passive);
    });

    test('muting via the mic button stops everything', () async {
      await notifier.toggleHandsFree();
      expect(speech.stopCalled, true);
      expect(readState().handsFreePhase, HandsFreePhase.off);
      expect(readState().isListening, false);
    });

    test('the active window relaxes to passive after the timeout', () async {
      final ws2 = _FakeWebSocketClient();
      final speech2 = _FakeSpeechService();
      final c2 = ProviderContainer(overrides: [
        websocketClientProvider.overrideWithValue(ws2),
        speechServiceProvider.overrideWithValue(speech2),
        cookingProvider.overrideWith((ref) => CookingNotifier(
              wsClient: ws2,
              speechService: speech2,
              restartDelay: Duration.zero,
              wakeWindow: const Duration(milliseconds: 50),
              onWakeSignal: () {},
            )),
      ]);
      addTearDown(c2.dispose);
      c2.listen(cookingProvider, (_, __) {});
      await c2.read(cookingProvider.notifier).startSession(recipe);

      speech2.resultListener!('hey salty', true);
      expect(c2.read(cookingProvider).handsFreePhase, HandsFreePhase.active);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(c2.read(cookingProvider).handsFreePhase, HandsFreePhase.passive);
    });

    test('unavailable mic leaves hands-free off and flags voiceAvailable',
        () async {
      final ws2 = _FakeWebSocketClient();
      final speech2 = _FakeSpeechService()..available = false;
      final c2 = ProviderContainer(overrides: [
        websocketClientProvider.overrideWithValue(ws2),
        speechServiceProvider.overrideWithValue(speech2),
        cookingProvider.overrideWith((ref) => CookingNotifier(
              wsClient: ws2,
              speechService: speech2,
              restartDelay: Duration.zero,
              onWakeSignal: () {},
            )),
      ]);
      addTearDown(c2.dispose);
      c2.listen(cookingProvider, (_, __) {});
      await c2.read(cookingProvider.notifier).startSession(recipe);

      final state = c2.read(cookingProvider);
      expect(state.handsFreePhase, HandsFreePhase.off);
      expect(state.voiceAvailable, false);
      // Auto-enable is silent (no error nag) when the mic just isn't granted.
      expect(state.error, isNull);
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

    test(
        'scroll_command with an int step jumps to that step and echoes '
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

    test('voice_intent question echoes the question and opens chat', () async {
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
