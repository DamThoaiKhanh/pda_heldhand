import 'package:flutter/material.dart';

// ✅ Import your tab screens
import '../views/request_order_screen.dart';
import '../views/demand_order_screen.dart';
import '../views/queue_order_screen.dart';
import '../views/running_order_screen.dart';
import '../views/robot_screen.dart';
import '../views/record_screen.dart';
import '../views/map_screen.dart';
import '../views/profile_screen.dart';
import '../views/settings_screen.dart';

class TabConfig {
  final String label;
  final IconData icon;
  final Widget page;

  const TabConfig({
    required this.label,
    required this.icon,
    required this.page,
  });
}

class Tabs {
  static const List<TabConfig> all = [
    TabConfig(
      // 0
      label: "Order",
      icon: Icons.assignment_outlined,
      page: RequestOrderScreen(),
    ),
    TabConfig(
      // 1
      label: "Demand",
      icon: Icons.layers_outlined,
      page: DemandOrderScreen(),
    ),
    TabConfig(
      // 2
      label: "Queue",
      icon: Icons.line_style_rounded,
      page: QueueOrderScreen(),
    ),
    TabConfig(
      // 3
      label: "Running",
      icon: Icons.article_outlined,
      page: RunningOrderScreen(),
    ),
    TabConfig(
      // 4
      label: "Record",
      icon: Icons.receipt_long_outlined,
      page: RecordScreen(),
    ),
    TabConfig(
      // 5
      label: "Robot",
      icon: Icons.smart_toy_outlined,
      page: RobotScreen(),
    ),
    TabConfig(
      // 6
      label: "Map",
      icon: Icons.location_on_outlined,
      page: MapScreen(),
    ),
    TabConfig(
      // 7
      label: "Profile",
      icon: Icons.person_outline,
      page: ProfileScreen(),
    ),
    TabConfig(
      // 8
      label: "Settings",
      icon: Icons.settings_outlined,
      page: SettingsScreen(),
    ),
  ];

  // Indexe ò the screen
  static int get order => 0;
  static int get demand => 1;
  static int get queue => 2;
  static int get running => 3;
  static int get record => 4;
  static int get robot => 5;
  static int get map => 6;
  static int get profile => 7;
  static int get settings => 8;
}
