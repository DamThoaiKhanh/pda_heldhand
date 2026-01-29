class WsMeta {
  final int code;
  final String? createAt;
  final String? msg;

  WsMeta({required this.code, this.createAt, this.msg});

  factory WsMeta.fromJson(Map<String, dynamic> json) {
    return WsMeta(
      code: json['code'] ?? -1,
      createAt: json['createAt'],
      msg: json['msg'],
    );
  }
}

class WsEvent {
  final int command;
  final Map<String, dynamic>? data;
  final WsMeta? meta;

  WsEvent({required this.command, this.data, this.meta});

  factory WsEvent.fromJson(Map<String, dynamic> json) {
    return WsEvent(
      command: json['command'] ?? -1,
      data: (json['data'] is Map<String, dynamic>)
          ? json['data'] as Map<String, dynamic>
          : null,
      meta: (json['meta'] is Map<String, dynamic>)
          ? WsMeta.fromJson(json['meta'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isOk => meta?.code == 0;
}
