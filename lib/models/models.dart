// Charging Mode
enum ChargingMode { free, auto, manual }

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

// Task Model
class Task {
  final String taskId;
  final String taskName;

  Task({required this.taskId, required this.taskName});

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(taskId: json['id'] ?? '', taskName: json['name'] ?? '');
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

// Queue Order Model
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

// Running Order Model
class RunningOrder {
  final String taskId;
  final String taskName;

  RunningOrder({required this.taskId, required this.taskName});

  factory RunningOrder.fromJson(Map<String, dynamic> json) {
    return RunningOrder(
      taskId: json['taskId'] ?? '',
      taskName: json['taskName'] ?? '',
    );
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
  final String ipAddress;
  final String name;
  final String? currentTask;
  final String? currentTaskId;
  final String status;
  final bool online;
  final int battery;
  final String? id;
  final double? confidence;
  final ChargingMode chargingMode;

  RobotStatus({
    required this.ipAddress,
    required this.name,
    this.currentTask,
    this.currentTaskId,
    required this.status,
    required this.online,
    required this.battery,
    this.id,
    this.confidence,
    required this.chargingMode,
  });

  factory RobotStatus.fromJson(Map<String, dynamic> json) {
    return RobotStatus(
      ipAddress: json['ipAddress'] ?? '',
      name: json['name'] ?? '',
      currentTask: json['currentTask'],
      currentTaskId: json['currentTaskId'],
      status: json['status'] ?? '',
      online: json['connected'] ?? false,
      battery: json['battery'] ?? 0,
      id: json['id'],
      confidence: json['confidence']?.toDouble(),
      chargingMode: ChargingMode.values[json['chargingMode'] ?? 0],
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
