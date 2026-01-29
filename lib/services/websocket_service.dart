import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as ws_status;

import '../models/ws_event.dart';

enum WsConnectionState { disconnected, connecting, connected, reconnecting }

class WebSocketService {
  WebSocketService({
    this.heartbeatInterval = const Duration(seconds: 20),
    this.reconnectBaseDelay = const Duration(seconds: 1),
    this.reconnectMaxDelay = const Duration(seconds: 30),
  });

  String? _url;
  void configure({required String url}) {
    _url = url;
  }

  final Duration heartbeatInterval;
  final Duration reconnectBaseDelay;
  final Duration reconnectMaxDelay;

  WebSocketChannel? _channel;

  final _eventController = StreamController<WsEvent>.broadcast();
  Stream<WsEvent> get events => _eventController.stream;

  final _stateController = StreamController<WsConnectionState>.broadcast();
  Stream<WsConnectionState> get state => _stateController.stream;

  WsConnectionState _currentState = WsConnectionState.disconnected;
  WsConnectionState get currentState => _currentState;

  StreamSubscription? _wsSubscription;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;

  bool _manualDisconnect = false;
  int _reconnectAttempt = 0;

  Future<void> _cleanupSocket() async {
    _stopHeartbeat();

    await _wsSubscription?.cancel();
    _wsSubscription = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}

    _channel = null;
  }

  Future<void> connect() async {
    if (_url == null) throw Exception("URL not configured");

    await _cleanupSocket();

    _manualDisconnect = false;
    _setState(WsConnectionState.connecting);

    try {
      final socket = await WebSocket.connect(
        _url!,
      ).timeout(const Duration(seconds: 5));

      _channel = IOWebSocketChannel(socket);

      _wsSubscription = _channel!.stream.listen(
        _handleMessage,
        onDone: () => _handleDisconnect(),
        onError: (error) => _handleDisconnect(error: error),
        cancelOnError: true,
      );

      _reconnectAttempt = 0;
      _setState(WsConnectionState.connected);
      _startHeartbeat();
    } catch (e) {
      _handleDisconnect(error: e);
    }
  }

  /// Disconnect manually (logout / exit)
  Future<void> disconnect() async {
    _manualDisconnect = true;

    _stopHeartbeat();
    _cancelReconnect();

    _setState(WsConnectionState.disconnected);

    await _wsSubscription?.cancel();
    _wsSubscription = null;

    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}

    _channel = null;
  }

  void sendCommand(int command, {Map<String, dynamic>? data}) {
    if (_channel == null || _currentState != WsConnectionState.connected)
      return;

    final payload = {"command": command, if (data != null) "data": data};

    try {
      _channel!.sink.add(jsonEncode(payload));
    } catch (e) {
      _handleDisconnect(error: e);
    }
  }

  /// Helper stream: listen only for one command code
  Stream<WsEvent> onCommand(int command) {
    return events.where((event) => event.command == command);
  }

  void _handleMessage(dynamic message) {
    try {
      final decoded = jsonDecode(message as String);

      if (decoded is Map<String, dynamic>) {
        final event = WsEvent.fromJson(decoded);
        _eventController.add(event);
      }
    } catch (_) {
      // ignore invalid json
    }
  }

  void _handleDisconnect({Object? error}) async {
    await _cleanupSocket();

    if (_manualDisconnect) {
      _setState(WsConnectionState.disconnected);
      return;
    }

    _setState(WsConnectionState.reconnecting);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectTimer?.isActive == true) return;

    _reconnectAttempt++;
    final delay = _calculateBackoffDelay(_reconnectAttempt);

    _reconnectTimer = Timer(delay, () async {
      if (_manualDisconnect) return;
      await connect();
    });
  }

  Duration _calculateBackoffDelay(int attempt) {
    print("WebSocketService: Reconnect attempt $attempt");
    final seconds = reconnectBaseDelay.inSeconds * (1 << (attempt - 1));
    final capped = seconds.clamp(
      reconnectBaseDelay.inSeconds,
      reconnectMaxDelay.inSeconds,
    );
    return Duration(seconds: capped);
  }

  void _startHeartbeat() {
    _stopHeartbeat();

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) {
      if (_channel == null || _currentState != WsConnectionState.connected)
        return;

      try {
        _channel!.sink.add(jsonEncode({"command": 0}));
      } catch (e) {
        _handleDisconnect(error: e);
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _setState(WsConnectionState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
    await _stateController.close();
  }
}
