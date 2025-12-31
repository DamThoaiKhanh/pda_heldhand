import 'package:flutter/foundation.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/services/storage_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<AppNotification> _notifications = [];
  Set<String> _selectedNotifications = {};
  bool _isSelectionMode = false;
  bool _isSelectAll = false;

  List<AppNotification> get notifications => _notifications;
  Set<String> get selectedNotifications => _selectedNotifications;
  bool get isSelectionMode => _isSelectionMode;
  bool get isSelectAll => _isSelectAll;

  // Load notifications from storage
  Future<void> loadNotifications() async {
    _notifications = _storageService.getNotifications();
    notifyListeners();
  }

  // Add notification
  Future<void> addNotification(AppNotification notification) async {
    _notifications.insert(0, notification);
    await _storageService.saveNotifications(_notifications);
    notifyListeners();
  }

  // Delete single notification
  Future<void> deleteNotification(String id) async {
    _notifications.removeWhere((n) => n.id == id);
    await _storageService.saveNotifications(_notifications);
    notifyListeners();
  }

  // Toggle selection mode
  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedNotifications.clear();
    }
    notifyListeners();
  }

  // Toggle notification selection
  void toggleNotificationSelection(String id) {
    if (_selectedNotifications.contains(id)) {
      _selectedNotifications.remove(id);
    } else {
      _selectedNotifications.add(id);
    }
    notifyListeners();
  }

  // Select all notifications
  void selectAll() {
    _selectedNotifications = _notifications.map((n) => n.id).toSet();
    _isSelectAll = true;
    notifyListeners();
  }

  // Select all notifications
  void unselectAll() {
    _selectedNotifications.clear();
    _isSelectAll = false;
    notifyListeners();
  }

  // Delete selected notifications
  Future<void> deleteSelected() async {
    _notifications.removeWhere((n) => _selectedNotifications.contains(n.id));
    await _storageService.saveNotifications(_notifications);
    _selectedNotifications.clear();
    _isSelectionMode = false;
    notifyListeners();
  }

  // Clear all notifications
  Future<void> clearAll() async {
    _notifications.clear();
    _selectedNotifications.clear();
    _isSelectionMode = false;
    await _storageService.saveNotifications(_notifications);
    notifyListeners();
  }
}
