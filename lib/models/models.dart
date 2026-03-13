// Charging Mode
enum ChargingMode { free, auto, manual }

// Robot Mode
enum RobotMode { auto, manual }

// Task Running State
enum TaskRunningState { stopped, running, paused, continuing, ending }

// User Model
class User {
  final String account;
  final String role;
  final String token;

  User({required this.account, required this.role, required this.token});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      account: json['account'] ?? '',
      role: json['role'] ?? '',
      token: json['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'account': account, 'role': role, 'token': token};
  }
}

// Server Config Model
class ServerConfig {
  final String ipAddress;
  final String port;

  ServerConfig({required this.ipAddress, required this.port});

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      ipAddress: json['ipAddress'] ?? '',
      port: json['port'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'ipAddress': ipAddress, 'port': port};
  }

  String get baseUrl => 'http://$ipAddress:$port';
}

// Task Information Model: Feedback from CORE
class Task {
  final String taskId;
  final String taskName;

  Task({required this.taskId, required this.taskName});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(taskId: json['id'] ?? '', taskName: json['name'] ?? '');
  }
}

// Robot Info Model
class RobotInfo {
  final String id;
  final String name;
  final String group;
  final String model;
  final String ipAddress;
  final String mac;
  final bool connected;

  const RobotInfo({
    required this.id,
    required this.name,
    required this.group,
    required this.model,
    required this.ipAddress,
    required this.mac,
    required this.connected,
  });

  factory RobotInfo.fromJson(Map<String, dynamic> json) {
    return RobotInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      group: json['group'] as String? ?? '',
      model: json['model'] as String? ?? '',
      ipAddress: json['ipAddress'] as String? ?? '',
      mac: json['mac'] as String? ?? '',
      connected: json['connected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group': group,
      'model': model,
      'ipAddress': ipAddress,
      'mac': mac,
      'connected': connected,
    };
  }

  RobotInfo copyWith({
    String? id,
    String? name,
    String? group,
    String? model,
    String? ipAddress,
    String? mac,
    bool? connected,
  }) {
    return RobotInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      model: model ?? this.model,
      ipAddress: ipAddress ?? this.ipAddress,
      mac: mac ?? this.mac,
      connected: connected ?? this.connected,
    );
  }

  @override
  String toString() {
    return 'RobotInfo(id: $id, name: $name, group: $group, model: $model, '
        'ipAddress: $ipAddress, mac: $mac, connected: $connected)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RobotInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ipAddress == other.ipAddress; // uniqueness per spec

  @override
  int get hashCode => id.hashCode ^ ipAddress.hashCode;
}

// Robot Model
class RobotStatus {
  final String id;
  final String ipAddress;
  final RobotMode mode;
  final double? x;
  final double? y;
  final double? theta;
  final double? confidence;
  final bool emergency;
  final String status;
  final int battery;
  final double? voltage;
  final double? current;
  final ChargingMode chargingMode;
  final String? currentTask;
  final String? currentTaskId;
  final TaskRunningState taskState;
  final bool online;

  RobotStatus({
    required this.ipAddress,
    required this.id,
    required this.mode,
    this.x,
    this.y,
    this.theta,
    this.confidence,
    required this.emergency,
    required this.battery,
    this.voltage,
    this.current,
    required this.chargingMode,
    this.currentTask,
    this.currentTaskId,
    required this.taskState,
    required this.status,
    required this.online,
  });

  factory RobotStatus.fromJson(Map<String, dynamic> json) {
    final dataStatus = json['dataStatus'] as Map<String, dynamic>? ?? {};
    final taskStatus = dataStatus['taskStatus'] as Map<String, dynamic>? ?? {};
    final currentTask =
        taskStatus['currentTask'] as Map<String, dynamic>? ?? {};

    return RobotStatus(
      ipAddress: json['ipAddress'] as String? ?? '',
      id: json['id'] as String? ?? '',
      mode:
          RobotMode.values[((dataStatus["mode"] as num?)?.toInt() ?? 0).clamp(
            0,
            RobotMode.values.length - 1,
          )],
      x: (dataStatus['x'] as num?)?.toDouble() ?? 0.0,
      y: (dataStatus['y'] as num?)?.toDouble() ?? 0.0,
      theta: (dataStatus['angle'] as num?)?.toDouble() ?? 0.0,
      confidence: (dataStatus['confidence'] as num?)?.toDouble(),
      emergency: dataStatus['emergency'] as bool? ?? false,
      battery: (dataStatus['batLevel'] as num?)?.toInt() ?? 0,
      voltage: (dataStatus['voltage'] as num?)?.toDouble(),
      current: (dataStatus['current'] as num?)?.toDouble(),
      currentTask: currentTask['taskName'] as String? ?? '',
      currentTaskId: currentTask['taskId'] as String? ?? '',
      taskState:
          TaskRunningState.values[((taskStatus["state"] as num?)?.toInt() ?? 0)
              .clamp(0, TaskRunningState.values.length - 1)],
      status: (dataStatus['runningState'] ?? '').toString(),
      online: true,
      chargingMode:
          ChargingMode.values[((dataStatus['chargingMode'] as num?)?.toInt() ??
                  0)
              .clamp(0, ChargingMode.values.length - 1)],
    );
  }

  static RobotStatus makeOffline() {
    return RobotStatus(
      ipAddress: "127.0.0.1",
      id: "AMR001",
      mode: RobotMode.manual,
      x: 0,
      y: 0,
      theta: 0,
      confidence: 0,
      emergency: true,
      battery: 0,
      voltage: 0,
      current: 0,
      chargingMode: ChargingMode.free,
      currentTask: "",
      currentTaskId: "",
      taskState: TaskRunningState.stopped,
      status: "Offline",
      online: false,
    );
  }
}

// Request Order Model
class RequestOrder {
  final String id;
  final String taskId;
  final String taskName;
  final String priority;
  final DateTime createdAt;

  RequestOrder({
    required this.id,
    required this.taskId,
    required this.taskName,
    required this.priority,
    required this.createdAt,
  });

  factory RequestOrder.fromJson(Map<String, dynamic> json) {
    return RequestOrder(
      id: json['id'] ?? '',
      taskId: json['taskId'] ?? '',
      taskName: json['taskName'] ?? '',
      priority: json['priority'] ?? '0',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'taskName': taskName,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Demand Order Model
class DemandOrder {
  final String taskId;
  final String taskName;
  final DateTime createdAt;

  DemandOrder({
    required this.taskId,
    required this.taskName,
    required this.createdAt,
  });

  factory DemandOrder.fromJson(Map<String, dynamic> json) {
    return DemandOrder(
      taskId: json['taskId'] ?? '',
      taskName: json['taskName'] ?? '',
      createdAt: json['createOn'] != null
          ? DateTime.parse(json['createOn']).toLocal()
          : DateTime.now(),
    );
  }
}

// Queue Order Model a.k.a Task Registration
class QueueOrder {
  final String taskId;
  final String taskName;
  final DateTime createdAt;

  QueueOrder({
    required this.taskId,
    required this.taskName,
    required this.createdAt,
  });

  factory QueueOrder.fromJson(Map<String, dynamic> json) {
    return QueueOrder(
      taskId: json['taskId'] ?? '',
      taskName: json['taskName'] ?? '',
      createdAt: json['createOn'] != null
          ? DateTime.parse(json['createOn']).toLocal()
          : DateTime.now(),
    );
  }
}

// Running Order Model a.k.a Task Executing
class RunningOrder {
  final String taskId;
  final String taskName;
  final String robotIp;
  final String robotName;
  final DateTime createdOn;
  final DateTime startOn;

  RunningOrder({
    required this.taskId,
    required this.taskName,
    required this.robotIp,
    required this.robotName,
    required this.createdOn,
    required this.startOn,
  });

  factory RunningOrder.fromJson(Map<String, dynamic> json) {
    return RunningOrder(
      taskId: json['taskId'] ?? '',
      taskName: json['taskName'] ?? '',
      robotIp: json['robotIp'] ?? '',
      robotName: json['robotName'] ?? '',
      createdOn: json['createdOn'] != null
          ? DateTime.parse(json['createdOn']).toLocal()
          : DateTime.now(),
      startOn: json['startOn'] != null
          ? DateTime.parse(json['startOn']).toLocal()
          : DateTime.now(),
    );
  }
}

// Record Model
class Record {
  final String taskId;
  final String taskName;
  final String status;
  final String? robotIp;
  final String? robotName;
  final DateTime? createdOn;

  Record({
    required this.taskId,
    required this.taskName,
    required this.status,
    this.robotIp,
    this.robotName,
    this.createdOn,
  });

  factory Record.fromJson(Map<String, dynamic> json) {
    return Record(
      taskId: json['taskId'] ?? '',
      taskName: json['taskName'] ?? '',
      status: json['status'] ?? '',
      robotIp: json['robotIp'],
      robotName: json['robotName'],
      createdOn: json['createdOn'] != null
          ? DateTime.parse(json['createdOn'])
          : null,
    );
  }
}

// Notification Model
class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.toString() == 'NotificationType.${json['type']}',
        orElse: () => NotificationType.info,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

enum NotificationType { info, warning, error }
