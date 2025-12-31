import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pda_handheld/models/models.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Server Config
  Future<void> saveServerConfig(ServerConfig config) async {
    await _prefs?.setString('server_config', jsonEncode(config.toJson()));
  }

  ServerConfig? getServerConfig() {
    final data = _prefs?.getString('server_config');
    if (data != null) {
      return ServerConfig.fromJson(jsonDecode(data));
    }
    return null;
  }

  // Login Credentials
  Future<void> saveCredentials(String account, String password) async {
    await _prefs?.setString('account', account);
    await _prefs?.setString('password', password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final account = _prefs?.getString('account');
    final password = _prefs?.getString('password');
    if (account != null && password != null) {
      return {'account': account, 'password': password};
    }
    return null;
  }

  Future<void> clearCredentials() async {
    await _prefs?.remove('account');
    await _prefs?.remove('password');
  }

  // Remember Me
  Future<void> setRememberMe(bool value) async {
    await _prefs?.setBool('remember_me', value);
  }

  bool getRememberMe() {
    return _prefs?.getBool('remember_me') ?? false;
  }

  // User
  Future<void> saveUser(User user) async {
    await _prefs?.setString('user', jsonEncode(user.toJson()));
  }

  User? getUser() {
    final data = _prefs?.getString('user');
    if (data != null) {
      return User.fromJson(jsonDecode(data));
    }
    return null;
  }

  Future<void> clearUser() async {
    await _prefs?.remove('user');
  }

  // Request Orders (per user account)
  Future<void> saveRequestOrders(
    String account,
    List<RequestOrder> orders,
  ) async {
    final key = 'request_orders_$account';
    final data = orders.map((o) => o.toJson()).toList();
    await _prefs?.setString(key, jsonEncode(data));
  }

  List<RequestOrder> getRequestOrders(String account) {
    final key = 'request_orders_$account';
    final data = _prefs?.getString(key);
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((json) => RequestOrder.fromJson(json)).toList();
    }
    return [];
  }

  // Notifications
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final data = notifications.map((n) => n.toJson()).toList();
    await _prefs?.setString('notifications', jsonEncode(data));
  }

  List<AppNotification> getNotifications() {
    final data = _prefs?.getString('notifications');
    if (data != null) {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((json) => AppNotification.fromJson(json)).toList();
    }
    return [];
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs?.clear();
  }
}
