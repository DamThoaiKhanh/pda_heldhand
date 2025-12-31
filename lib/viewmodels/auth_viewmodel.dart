import 'package:flutter/foundation.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/services/api_service.dart';
import 'package:pda_handheld/services/storage_service.dart';

class AuthViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthViewModel(this._apiService, this._storageService);

  User? _user;
  ServerConfig? _serverConfig;
  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  User? get user => _user;
  ServerConfig? get serverConfig => _serverConfig;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get rememberMe => _rememberMe;

  Future<void> init() async {
    _serverConfig = _storageService.getServerConfig();
    _rememberMe = _storageService.getRememberMe();
    _user = _storageService.getUser();

    if (_serverConfig != null) {
      _apiService.setBaseUrl(_serverConfig!.baseUrl);
    }

    notifyListeners();
  }

  Future<bool> login(String account, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_serverConfig == null) {
        throw Exception('Server configuration not set');
      }

      final response = await _apiService.login(account, password);
      _user = User.fromJson(response);

      await _storageService.saveUser(_user!);

      if (_rememberMe) {
        await _storageService.saveCredentials(account, password);
      } else {
        await _storageService.clearCredentials();
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> saveServerConfig(String ipAddress, String port) async {
    _serverConfig = ServerConfig(ipAddress: ipAddress, port: port);
    await _storageService.saveServerConfig(_serverConfig!);
    _apiService.setBaseUrl(_serverConfig!.baseUrl);
    notifyListeners();
  }

  void setRememberMe(bool value) {
    _rememberMe = value;
    _storageService.setRememberMe(value);
    notifyListeners();
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    if (_rememberMe) {
      return await _storageService.getCredentials();
    }
    return null;
  }

  Future<void> logout() async {
    _user = null;
    await _storageService.clearUser();
    if (!_rememberMe) {
      await _storageService.clearCredentials();
    }
    notifyListeners();
  }
}
