import 'dart:async';
import 'package:flutter/material.dart';
import '../core/service_locator.dart';
import '../models/ws_event.dart';
import '../models/models.dart';
import '../services/websocket_service.dart';

enum WsCommands {
  getAutoResponseRobotStatus(1000),
  robotConnectionChange(1002),
  getRobotListStatus(1004),
  getRobotStatusById(1006);

  final int value;
  const WsCommands(this.value);

  static WsCommands? fromValue(int value) {
    for (var command in WsCommands.values) {
      if (command.value == value) {
        return command;
      }
    }
    return null;
  }
}

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

  // Websocket connection status
  bool get isConnected => _connectionState == WsConnectionState.connected;

  final Map<String, dynamic> _robotData = {};
  Map<String, dynamic> get robotData => _robotData;

  final Map<String, bool> _allRobotConnection = {};
  Map<String, bool> get allRobotConnection => _allRobotConnection;
  set allRobotConnection(Map<String, bool> value) {
    _allRobotConnection
      ..clear()
      ..addAll(value);
    notifyListeners();
  }

  bool getRobotConnection(String robotId) =>
      _allRobotConnection[robotId] ?? false;
  void setRobotConnection(String robotId, bool connected) {
    _allRobotConnection[robotId] = connected;
    // notifyListeners();
  }

  // All robot poses, keyed by robot ID
  final Map<String, RobotPose> _robotPoses = {};
  Map<String, RobotPose> get robotPoses => _robotPoses;
  RobotPose? getRobotPose(String robotId) => _robotPoses[robotId];

  // All robot status, keyed by robot ID
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

  @override
  void dispose() {
    _wsSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  void sendCommand(int command, {Map<String, dynamic>? data}) {
    _ws.sendCommand(command, data: data);
  }

  void _handleEvent(WsEvent event) {
    if (!event.isOk) return;

    _robotData["lastCommand"] = event.command;
    _robotData["lastData"] = event.data;

    debugPrint("Websocket received event: command=${event.command}");
    // debugPrint("Received event: command=${event.command}, data=${event.data}");

    if (event.command == WsCommands.robotConnectionChange.value) {
      _updateAllRobotConnections(event.command, event.data);
      notifyListeners();
      return;
    } else if (event.command == WsCommands.getRobotListStatus.value) {
      _updateAllRobotPoses(event.command, event.data);
      notifyListeners();
      return;
    } else if (event.command == WsCommands.getRobotStatusById.value) {
      _updataRobotStatus(event.command, event.data);
      notifyListeners();
      return;
    }
  }

  void _updateAllRobotConnections(int command, dynamic data) {
    if (command != WsCommands.robotConnectionChange.value) return;

    if (data == null || data is! Map) return;

    final robotConnectionChange = data['robotConnectionChange'];
    if (robotConnectionChange is! Map) return;

    final robotId = robotConnectionChange['id']?.toString() ?? '';
    if (robotId.isEmpty) return;

    final connected = robotConnectionChange['connected'] as bool? ?? false;
    if (robotId.isNotEmpty) {
      _allRobotConnection[robotId] = connected;
    }
  }

  void _updateAllRobotPoses(int command, dynamic data) {
    if (command != WsCommands.getRobotListStatus.value) return;

    if (data == null || data is! Map) return;

    final robotListStatus = data['robotListStatus'];
    if (robotListStatus is! List) return;

    for (final item in robotListStatus) {
      if (item is! Map) continue;

      final robotId = item['id']?.toString() ?? '';
      if (robotId.isEmpty) continue;

      if (item is Map<String, dynamic>) {
        final statusData = RobotStatus.fromJson(item);
        _allRobotStatus[robotId] = statusData;

        _robotPoses[robotId] = RobotPose(
          robotId: robotId,
          x: statusData.x?.toDouble() ?? 0.0,
          y: statusData.y?.toDouble() ?? 0.0,
          theta: statusData.theta,
          online: true,
        );
      }
    }
  }

  void _updataRobotStatus(int command, dynamic data) {
    if (command != WsCommands.getRobotStatusById.value) return;
    if (data is Map<String, dynamic>) {
      final robotStatus = RobotStatus.fromJson(data);
      _allRobotStatus[robotStatus.id] = robotStatus;
    }
  }
}
