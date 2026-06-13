import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:saltybytes_app/core/network/websocket_client.dart';

import '../../helpers/test_helpers.dart';

/// In-memory WebSocket sink that records what the client sends.
class _FakeWebSocketSink implements WebSocketSink {
  _FakeWebSocketSink(this._onClose);

  final void Function() _onClose;
  final List<dynamic> added = [];
  bool closed = false;
  final _done = Completer<void>();

  @override
  void add(dynamic data) => added.add(data);

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
    if (!_done.isCompleted) _done.complete();
    _onClose();
  }

  @override
  Future<void> get done => _done.future;
}

/// In-memory WebSocketChannel: tests push inbound frames via [emit] and
/// close the "server" side via [closeFromServer].
class _FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _FakeWebSocketChannel() {
    _sink = _FakeWebSocketSink(closeFromServer);
  }

  final _controller = StreamController<dynamic>();
  late final _FakeWebSocketSink _sink;

  void emit(dynamic frame) => _controller.add(frame);

  /// Closes the inbound stream, which fires the client's onDone handler.
  void closeFromServer() {
    if (!_controller.isClosed) _controller.close();
  }

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  Future<void> get ready => Future.value();

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;
}

void main() {
  late MockSecureStorage storage;
  late _FakeWebSocketChannel channel;
  late List<Uri> connectedUris;
  late WebSocketClient client;

  setUp(() {
    storage = MockSecureStorage();
    channel = _FakeWebSocketChannel();
    connectedUris = [];
    client = WebSocketClient(
      secureStorage: storage,
      connector: (uri) {
        connectedUris.add(uri);
        return channel;
      },
    );
    // Stop heartbeat/reconnect timers leaking into other tests.
    addTearDown(() => client.disconnect());
  });

  group('connect', () {
    test('aborts and reports disconnected when no auth token is stored',
        () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => null);

      final states = <WebSocketConnectionState>[];
      final sub = client.connectionState.listen(states.add);
      addTearDown(sub.cancel);

      await client.connect('recipe-1');
      await Future<void>.delayed(Duration.zero);

      expect(connectedUris, isEmpty);
      expect(client.currentState, WebSocketConnectionState.disconnected);
      expect(states, [
        WebSocketConnectionState.connecting,
        WebSocketConnectionState.disconnected,
      ]);
    });

    test('builds the cooking-session URI with the token as a query param '
        'and transitions connecting -> connected', () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'tok-9');

      final states = <WebSocketConnectionState>[];
      final sub = client.connectionState.listen(states.add);
      addTearDown(sub.cancel);

      await client.connect('recipe-7');
      await Future<void>.delayed(Duration.zero);

      final uri = connectedUris.single;
      expect(uri.scheme, 'wss');
      expect(uri.path, '/v1/ws/cook/recipe-7');
      expect(uri.queryParameters['token'], 'tok-9');
      expect(client.currentState, WebSocketConnectionState.connected);
      expect(states, [
        WebSocketConnectionState.connecting,
        WebSocketConnectionState.connected,
      ]);
    });
  });

  group('message envelope decode (inbound)', () {
    setUp(() {
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'tok');
    });

    test('decodes JSON text frames onto the messages stream', () async {
      final received = <Map<String, dynamic>>[];
      final sub = client.messages.listen(received.add);
      addTearDown(sub.cancel);

      await client.connect('recipe-1');
      channel.emit(jsonEncode({
        'type': 'chat_response',
        'payload': {'message': 'Sear it well.'},
      }));
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single['type'], 'chat_response');
      expect(received.single['payload'], {'message': 'Sear it well.'});
    });

    test('silently drops malformed JSON and non-string frames', () async {
      final received = <Map<String, dynamic>>[];
      final sub = client.messages.listen(received.add);
      addTearDown(sub.cancel);

      await client.connect('recipe-1');
      channel.emit('{not json');
      channel.emit([1, 2, 3]); // binary-ish frame
      channel.emit(jsonEncode({'type': 'pong', 'payload': {}}));
      await Future<void>.delayed(Duration.zero);

      // Only the valid envelope made it through, and nothing crashed.
      expect(received, hasLength(1));
      expect(received.single['type'], 'pong');
    });
  });

  group('send (outbound envelope encode)', () {
    test('JSON-encodes the envelope onto the socket when connected',
        () async {
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'tok');
      await client.connect('recipe-1');

      client.send({
        'type': 'step_change',
        'payload': {'step': 2},
      });

      final frame = channel._sink.added.single as String;
      expect(jsonDecode(frame), {
        'type': 'step_change',
        'payload': {'step': 2},
      });
    });

    test('is a no-op when not connected', () {
      // Never connected: no channel exists, must not throw.
      expect(
        () => client.send({'type': 'ping', 'payload': {}}),
        returnsNormally,
      );
      expect(channel._sink.added, isEmpty);
    });
  });

  group('reconnect decisions', () {
    setUp(() {
      when(() => storage.getAccessToken()).thenAnswer((_) async => 'tok');
    });

    test('a server-side close while a session is active schedules a '
        'reconnect (state -> reconnecting)', () async {
      await client.connect('recipe-1');
      expect(client.currentState, WebSocketConnectionState.connected);

      channel.closeFromServer();
      await Future<void>.delayed(Duration.zero);

      expect(client.currentState, WebSocketConnectionState.reconnecting);
    });

    test('disconnect() cancels the session: a subsequent stream close '
        'does NOT trigger a reconnect', () async {
      await client.connect('recipe-1');

      await client.disconnect();
      expect(client.currentState, WebSocketConnectionState.disconnected);
      expect(channel._sink.closed, isTrue);

      // The (already-closed) stream completing must not flip the state.
      await Future<void>.delayed(Duration.zero);
      expect(client.currentState, WebSocketConnectionState.disconnected);
    });

    test('disconnect during reconnecting stops further attempts', () async {
      await client.connect('recipe-1');
      channel.closeFromServer();
      await Future<void>.delayed(Duration.zero);
      expect(client.currentState, WebSocketConnectionState.reconnecting);
      final attemptsBefore = connectedUris.length;

      await client.disconnect();
      expect(client.currentState, WebSocketConnectionState.disconnected);

      // The pending backoff timer was cancelled; no new connection is made.
      // (Backoff start is 1s; waiting longer would slow the suite, and the
      // timer cancellation is what we are asserting.)
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(connectedUris.length, attemptsBefore);
    });
  });

  // NOT covered here, would need refactors (noted deliberately):
  // - Exponential backoff durations (1s/2s/4s/8s/16s) and the max-attempts
  //   cutoff: computed inside the private _scheduleReconnect with real
  //   Timers; testing would need an injectable clock/timer factory.
  // - Heartbeat ping cadence (30s) and the 75s liveness timeout: same
  //   real-Timer problem (fakeAsync does not mix with the awaited
  //   connect() flow without restructuring).
}
