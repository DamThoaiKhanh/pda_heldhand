import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pda_handheld/models/models.dart';

class ApiService {
  String? _baseUrl = "http://10.0.2.2:8088";

  void setBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  String get baseUrl => _baseUrl ?? '';

  // Authentication
  Future<Map<String, dynamic>> login(String account, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': account, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Login failed');
    }
  }

  // Get Tasks
  Future<List<Task>> getTasks() async {
    print('Fetching tasks from $_baseUrl/api/v1/tasks');
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/tasks'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  // Send Request Order
  Future<void> sendRequestOrder(RequestOrder order) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v1/tasks/demands'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'taskId': order.taskId,
        'taskName': order.taskName,
        'priority': order.priority,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to send request order');
    }
  }

  // Get Demand Orders
  Future<List<DemandOrder>> getDemandOrders() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/tasks/demands'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data.map((json) => DemandOrder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load demand orders');
    }
  }

  // Confirm Demand Order
  Future<void> confirmDemandOrder(String taskId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders/demand/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'taskId': taskId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to confirm demand order');
    }
  }

  // Delete Demand Order
  Future<void> deleteDemandOrder(String taskId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/orders/demand/$taskId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete demand order');
    }
  }

  // Get Running Orders
  Future<List<RunningOrder>> getRunningOrders() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/tasks/executings'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data.map((json) => RunningOrder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load running orders');
    }
  }

  // Cancel Running Order
  Future<void> cancelRunningOrder(String taskId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/orders/running/cancel'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'taskId': taskId}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to cancel running order');
    }
  }

  // Get Robots
  Future<List<Robot>> getRobots() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v1/robots'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body)["data"];
      return data.map((json) => Robot.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load robots');
    }
  }

  // Get Robot Detail
  Future<Robot> getRobotDetail(String ipAddress) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/robots/$ipAddress'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Robot.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load robot detail');
    }
  }

  // Get Records
  Future<List<Record>> getRecords() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/records'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Record.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load records');
    }
  }

  // Get Record Detail
  Future<Record> getRecordDetail(String taskId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/records/$taskId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return Record.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load record detail');
    }
  }
}
