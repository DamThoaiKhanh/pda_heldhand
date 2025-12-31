import 'package:flutter/foundation.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/services/api_service.dart';

class RobotViewModel extends ChangeNotifier {
  final ApiService _apiService;

  RobotViewModel(this._apiService);

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
  Future<void> fetchRobotDetail(String ipAddress) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedRobot = await _apiService.getRobotDetail(ipAddress);
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

  void clearSelectedRobot() {
    _selectedRobot = null;
    notifyListeners();
  }

  void clearSelectedRecord() {
    _selectedRecord = null;
    notifyListeners();
  }
}
