import 'package:flutter/foundation.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/services/api_service.dart';
import 'package:pda_handheld/services/storage_service.dart';

class OrderViewModel extends ChangeNotifier {
  final ApiService _apiService;
  final StorageService _storageService = StorageService();

  OrderViewModel(this._apiService);

  List<RequestOrder> _requestOrders = [];
  List<DemandOrder> _demandOrders = [];
  List<RunningOrder> _runningOrders = [];
  List<Task> _availableTasks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RequestOrder> get requestOrders => _requestOrders;
  List<DemandOrder> get demandOrders => _demandOrders;
  List<RunningOrder> get runningOrders => _runningOrders;
  List<Task> get availableTasks => _availableTasks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load request orders from storage
  Future<void> loadRequestOrders(String account) async {
    _requestOrders = _storageService.getRequestOrders(account);
    notifyListeners();
  }

  // Add new request order
  Future<void> addRequestOrder(String account, RequestOrder order) async {
    _requestOrders.add(order);
    await _storageService.saveRequestOrders(account, _requestOrders);
    notifyListeners();
  }

  // Update request order
  Future<void> updateRequestOrder(
    String account,
    String orderId,
    RequestOrder updatedOrder,
  ) async {
    final index = _requestOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _requestOrders[index] = updatedOrder;
      await _storageService.saveRequestOrders(account, _requestOrders);
      notifyListeners();
    }
  }

  // Delete request order
  Future<void> deleteRequestOrder(String account, String orderId) async {
    _requestOrders.removeWhere((o) => o.id == orderId);
    await _storageService.saveRequestOrders(account, _requestOrders);
    notifyListeners();
  }

  // Send request order to server
  Future<bool> sendRequestOrder(RequestOrder order) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.sendRequestOrder(order);
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

  // Get available tasks from server
  Future<void> fetchAvailableTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _availableTasks = await _apiService.getTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get demand orders from server
  Future<void> fetchDemandOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _demandOrders = await _apiService.getDemandOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Confirm demand order
  Future<bool> confirmDemandOrder(String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.confirmDemandOrder(taskId);
      await fetchDemandOrders(); // Refresh list
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

  // Delete demand order
  Future<bool> deleteDemandOrder(String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.deleteDemandOrder(taskId);
      _demandOrders.removeWhere((o) => o.taskId == taskId);
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

  // Get running orders from server
  Future<void> fetchRunningOrders() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _runningOrders = await _apiService.getRunningOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cancel running order
  Future<bool> cancelRunningOrder(String taskId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.cancelRunningOrder(taskId);
      _runningOrders.removeWhere((o) => o.taskId == taskId);
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
}
