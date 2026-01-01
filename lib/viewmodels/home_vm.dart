import 'package:flutter/foundation.dart';
import '../models/bottom_tab.dart';

// ✅ Import your screens here
import '../views/request_order_screen.dart';
// import '../pages/demand/demand_page.dart';
// etc...

import 'package:flutter/material.dart';

/// TEMP page — replace with your real screens
class TempPage extends StatelessWidget {
  final String title;
  const TempPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) =>
      Center(child: Text(title, style: const TextStyle(fontSize: 30)));
}

class HomeViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  late final List<BottomTab> tabs;

  HomeViewModel() {
    tabs = [
      BottomTab(
        label: "Order",
        icon: Icons.shopping_bag_outlined,
        page: const RequestOrderScreen(),
      ),
      BottomTab(
        label: "Demand",
        icon: Icons.layers_outlined,
        page: const TempPage(title: "Demand"),
      ),
      BottomTab(
        label: "Running",
        icon: Icons.timer_outlined,
        page: const TempPage(title: "Running"),
      ),
      BottomTab(
        label: "Robot",
        icon: Icons.smart_toy_outlined,
        page: const TempPage(title: "Robot"),
      ),
      BottomTab(
        label: "Record",
        icon: Icons.description_outlined,
        page: const TempPage(title: "Record"),
      ),
      BottomTab(
        label: "Map",
        icon: Icons.map_outlined,
        page: const TempPage(title: "Map"),
      ),
      BottomTab(
        label: "Profile",
        icon: Icons.person_outline,
        page: const TempPage(title: "Profile"),
      ),
      BottomTab(
        label: "Settings",
        icon: Icons.settings_outlined,
        page: const TempPage(title: "Settings"),
      ),
    ];
  }

  void selectTab(int index) {
    if (index == _selectedIndex) return;
    _selectedIndex = index;
    notifyListeners();
  }
}
