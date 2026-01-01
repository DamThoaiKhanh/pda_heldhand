import 'package:flutter/material.dart';

class BottomNavViewModel extends ChangeNotifier {
  int _index = 0;
  int _previousIndex = 0;

  int get index => _index;
  int get previousIndex => _previousIndex;

  void setIndex(int newIndex) {
    _previousIndex = _index;
    _index = newIndex;
    notifyListeners();
  }
}
