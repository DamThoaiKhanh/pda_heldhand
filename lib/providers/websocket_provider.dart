import 'dart:async';
import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../models/ws_event.dart';
import '../models/models.dart';
import '../services/websocket_service.dart';

class RobotPose {
  final String robotId;
  final double x;
  final double y;
  final double? theta;
  final bool online;

  const RobotPose({
    required this.robotId,
    required this.x,
    required this.y,
    this.theta,
    this.online = true,
  });

  factory RobotPose.fromJson(Map json) {
    return RobotPose(
      robotId: (json['robotId'] ?? json['id'] ?? '').toString(),
      x: (json['x'] as num?)?.toDouble() ?? 0.0,
      y: (json['y'] as num?)?.toDouble() ?? 0.0,
      theta: (json['theta'] as num?)?.toDouble(),
      online: json['online'] as bool? ?? json['connected'] as bool? ?? true,
    );
  }
}

class WebsocketProvider extends ChangeNotifier {
  final WebSocketService _ws = getIt();

  StreamSubscription? _wsSub;
  StreamSubscription? _stateSub;

  WsConnectionState _connectionState = WsConnectionState.disconnected;
  WsConnectionState get connectionState => _connectionState;

  final Map<String, dynamic> _robotData = {};
  Map<String, dynamic> get robotData => _robotData;

  final Map<String, RobotPose> _robotPoses = {};
  Map<String, RobotPose> get robotPoses => _robotPoses;

  RobotPose? getRobotPose(String robotId) => _robotPoses[robotId];

  bool get isConnected => _connectionState == WsConnectionState.connected;

  final Map<String, RobotStatus> _allRobotStatus = {};
  Map<String, RobotStatus> get allRobotStatus => _allRobotStatus;
  RobotStatus? getRobotStatus(String robotId) => _allRobotStatus[robotId];

  Future initRealtime({required String wsUrl}) async {
    _ws.configure(url: wsUrl);

    _stateSub?.cancel();
    _stateSub = _ws.state.listen((s) {
      _connectionState = s;
      notifyListeners();
    });

    _wsSub?.cancel();
    _wsSub = _ws.events.listen(_handleEvent);

    await _ws.connect();
  }

  void _handleEvent(WsEvent event) {
    if (!event.isOk) return;

    _robotData["lastCommand"] = event.command;
    _robotData["lastData"] = event.data;

    debugPrint("Websocket received event: command=${event.command}");
    // debugPrint("Received event: command=${event.command}, data=${event.data}");

    if (event.command == 1004) {
      _updateAllRobotPoses(event.command, event.data);
    } else if (event.command == 1006) {
      if (event.data is Map<String, dynamic>) {
        final robotStatus = RobotStatus.fromJson(
          event.data as Map<String, dynamic>,
        );
        _allRobotStatus[robotStatus.id] = robotStatus;
      }
    }

    notifyListeners();
  }

  void _updateAllRobotPoses(int command, dynamic data) {
    if (command != 1004) return;

    if (data == null || data is! Map) return;

    final robotListStatus = data['robotListStatus'];
    if (robotListStatus is! List) return;

    for (final item in robotListStatus) {
      if (item is! Map) continue;

      final robotId = item['id']?.toString() ?? '';
      if (robotId.isEmpty) continue;

      final dataStatus = item['dataStatus'];
      if (dataStatus is! Map) continue;

      final x = (dataStatus['x'] as num?)?.toDouble();
      final y = (dataStatus['y'] as num?)?.toDouble();
      final angle = (dataStatus['angle'] as num?)?.toDouble();

      if (x == null || y == null) continue;

      _robotPoses[robotId] = RobotPose(
        robotId: robotId,
        x: x,
        y: y,
        theta: angle,
        online: true,
      );
    }
  }

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
