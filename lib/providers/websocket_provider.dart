import 'dart:async';

import 'package:flutter/material.dart';

import '../core/service_locator.dart';
import '../models/ws_event.dart';
import '../services/websocket_service.dart';

class WebsocketProvider extends ChangeNotifier {
  final WebSocketService _ws = getIt<WebSocketService>();

  StreamSubscription<WsEvent>? _wsSub;
  StreamSubscription<WsConnectionState>? _stateSub;

  WsConnectionState _connectionState = WsConnectionState.disconnected;
  WsConnectionState get connectionState => _connectionState;

  /// ✅ Example shared data (you will replace with real fields)
  final Map<String, dynamic> _robotData = {};
  Map<String, dynamic> get robotData => _robotData;

  bool get isConnected => _connectionState == WsConnectionState.connected;

  /// Call once at app start or after login
  Future<void> initRealtime({required String wsUrl}) async {
    _ws.configure(url: wsUrl);

    // listen state
    _stateSub?.cancel();
    _stateSub = _ws.state.listen((s) {
      _connectionState = s;
      notifyListeners();
    });

    // listen events (single place)
    _wsSub?.cancel();
    _wsSub = _ws.events.listen(_handleEvent);

    await _ws.connect();
  }

  void _handleEvent(WsEvent event) {
    if (!event.isOk) return;

    // ✅ update shared state here based on command
    // Replace this example logic:
    _robotData["lastCommand"] = event.command;
    _robotData["lastData"] = event.data;

    notifyListeners();
  }

  /// When you want to send any command
  void sendCommand(int command, {Map<String, dynamic>? data}) {
    _ws.sendCommand(command, data: data);
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }
}
