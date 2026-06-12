import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:saltybytes_app/core/network/api_client.dart';
import 'package:saltybytes_app/core/network/websocket_client.dart';
import 'package:saltybytes_app/core/providers/auth_provider.dart';
import 'package:saltybytes_app/core/storage/secure_storage.dart';
import 'package:saltybytes_app/core/voice/speech_service.dart';

class MockDio extends Mock implements Dio {}

class MockSecureStorage extends Mock implements SecureStorage {}

class MockApiClient extends Mock implements ApiClient {}

/// Fake auth notifier that reports the given [status] immediately
/// (authenticated by default).
///
/// Use with `authStateProvider.overrideWith(FakeAuthNotifier.new)` so
/// providers that watch auth (e.g. familyProvider) can build in tests, or
/// `overrideWith(() => FakeAuthNotifier(AuthStatus.unauthenticated))` to
/// exercise the signed-out paths.
class FakeAuthNotifier extends AsyncNotifier<AuthStatus>
    implements AuthNotifier {
  FakeAuthNotifier([this.status = AuthStatus.authenticated]);

  final AuthStatus status;

  @override
  Future<AuthStatus> build() async => status;

  @override
  Future<void> login(
      {required String username, required String password}) async {}

  @override
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}
}

/// Fake WebSocket client that records outgoing messages and lets tests
/// emit incoming server messages onto the stream.
class FakeWebSocketClient implements WebSocketClient {
  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final _messageController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Every envelope sent through [send], in order.
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
class FakeSpeechService implements SpeechService {
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

/// Creates a [ProviderContainer] with common overrides for testing.
///
/// Pass additional [overrides] to customise individual providers.
ProviderContainer createTestContainer({
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: overrides,
  );
  return container;
}

/// Convenience: build a [Response] with the given [data] and [statusCode].
Response<T> fakeResponse<T>(
  T data, {
  int statusCode = 200,
  RequestOptions? requestOptions,
}) {
  return Response<T>(
    data: data,
    statusCode: statusCode,
    requestOptions: requestOptions ?? RequestOptions(path: '/test'),
  );
}

/// A [HttpClientAdapter] that routes every request through [handler],
/// letting interceptor tests run a REAL Dio pipeline fully offline.
///
/// Install with `apiClient.dio.httpClientAdapter = FakeHttpClientAdapter(...)`.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  /// Every request this adapter served, in order.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// JSON [ResponseBody] for [FakeHttpClientAdapter] handlers.
ResponseBody jsonResponseBody(Object? data, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(data),
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
