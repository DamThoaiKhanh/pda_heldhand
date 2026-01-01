import 'package:flutter/material.dart';

class BottomTab {
  final String label;
  final IconData icon;
  final Widget page;

  const BottomTab({
    required this.label,
    required this.icon,
    required this.page,
  });
}
