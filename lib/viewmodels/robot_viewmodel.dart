import 'package:flutter/foundation.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/services/api_service.dart';
import 'package:pda_handheld/services/storage_service.dart';

class RobotViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService = StorageService();

  List<Robot> _robots = [];
  Robot? _selectedRobot;
  List<Record> _records = [];
  Record? _selectedRecord;
  bool _isLoading = false;
  String? _errorMessage;

  List<Robot> get robots => _robots;
  Robot? get selectedRobot => _selectedRobot;
  List<Record> get records => _records;
  Record? get selectedRecord => _selectedRecord;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RobotViewModel(this._apiService) {
    init();
  }

  Future<void> init() async {
    _apiService.setBaseUrl(
      _storageService.getServerConfig()?.baseUrl ?? "http://10.0.2.2:8088",
    );
    final user = _storageService.getUser();
    if (user != null) {
      _apiService.setToken(user.token);
    }
  }

  // Fetch robots from server
  Future<void> fetchRobots() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _robots = await _apiService.getRobots();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch robot detail
  Future<void> fetchRobotDetail(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRobot = await _apiService.getRobotDetail(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch records from server
  Future<void> fetchRecords() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _records = await _apiService.getRecords();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch record detail
  Future<void> fetchRecordDetail(String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRecord = await _apiService.getRecordDetail(taskId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSelectedRobot({bool notify = true}) {
    _selectedRobot = null;
    if (notify) notifyListeners();
  }

  void clearSelectedRecord({bool notify = true}) {
    _selectedRecord = null;
    if (notify) notifyListeners();
  }
}
