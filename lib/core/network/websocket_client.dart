import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../storage/secure_storage.dart';
import 'api_endpoints.dart';

final websocketClientProvider = Provider<WebSocketClient>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return WebSocketClient(secureStorage: secureStorage);
});

enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class WebSocketClient {
  WebSocketClient({required SecureStorage secureStorage})
      : _secureStorage = secureStorage;

  final SecureStorage _secureStorage;

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  String? _currentRecipeId;

  final _stateController =
      StreamController<WebSocketConnectionState>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<WebSocketConnectionState> get connectionState =>
      _stateController.stream;
  Stream<Map<String, dynamic>> get messages => _messageController.stream;

  WebSocketConnectionState _currentState = WebSocketConnectionState.disconnected;
  WebSocketConnectionState get currentState => _currentState;

  Future<void> connect(String recipeId) async {
    _currentRecipeId = recipeId;
    _reconnectAttempts = 0;
    await _establishConnection();
  }

  Future<void> _establishConnection() async {
    if (_currentRecipeId == null) return;

    _updateState(WebSocketConnectionState.connecting);

    try {
      final token = await _secureStorage.getAccessToken();
      if (token == null) {
        developer.log('No auth token for WebSocket', name: 'WS');
        _updateState(WebSocketConnectionState.disconnected);
        return;
      }

      final uri = Uri.parse(
        ApiEndpoints.wsCookingSession(_currentRecipeId!),
      ).replace(queryParameters: {'token': token});

      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _updateState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
    } catch (e) {
      developer.log('WebSocket connection failed: $e', name: 'WS');
      _scheduleReconnect();
    }
  }

  void _onMessage(dynamic data) {
    try {
      final Map<String, dynamic> message;
      if (data is String) {
        message = jsonDecode(data) as Map<String, dynamic>;
      } else {
        return;
      }
      developer.log('WS << ${message['type']}', name: 'WS');
      _messageController.add(message);
    } catch (e) {
      developer.log('Failed to parse WS message: $e', name: 'WS');
    }
  }

  void _onError(dynamic error) {
    developer.log('WebSocket error: $error', name: 'WS');
    _scheduleReconnect();
  }

  void _onDone() {
    developer.log('WebSocket closed', name: 'WS');
    _stopHeartbeat();
    if (_currentRecipeId != null) {
      _scheduleReconnect();
    }
  }

  void send(Map<String, dynamic> message) {
    if (_channel == null || _currentState != WebSocketConnectionState.connected) {
      developer.log('Cannot send, not connected', name: 'WS');
      return;
    }
    final encoded = jsonEncode(message);
    developer.log('WS >> ${message['type']}', name: 'WS');
    _channel!.sink.add(encoded);
  }

  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      send({'type': 'ping'});
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      developer.log('Max reconnect attempts reached', name: 'WS');
      _updateState(WebSocketConnectionState.disconnected);
      return;
    }

    _updateState(WebSocketConnectionState.reconnecting);
    _reconnectAttempts++;

    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delay = Duration(seconds: 1 << (_reconnectAttempts - 1));
    developer.log(
      'Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts)',
      name: 'WS',
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _establishConnection);
  }

  void _updateState(WebSocketConnectionState state) {
    _currentState = state;
    _stateController.add(state);
  }

  Future<void> disconnect() async {
    _currentRecipeId = null;
    _reconnectTimer?.cancel();
    _stopHeartbeat();
    await _channel?.sink.close();
    _channel = null;
    _updateState(WebSocketConnectionState.disconnected);
  }

  void dispose() {
    disconnect();
    _stateController.close();
    _messageController.close();
  }
}
