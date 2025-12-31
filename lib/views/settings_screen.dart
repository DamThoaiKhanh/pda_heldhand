import 'package:flutter/material.dart';
import 'package:pda_handheld/views/request_order_screen.dart';
import 'package:pda_handheld/views/robot_screen.dart';
import 'package:pda_handheld/views/record_screen.dart';
import 'package:pda_handheld/views/map_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedIndex = 7;
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = false;
  String _selectedTheme = 'System';

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.smart_toy, 'label': 'Robot'},
      {'icon': Icons.history, 'label': 'Record'},
      {'icon': Icons.map, 'label': 'Map'},
      {'icon': Icons.settings, 'label': 'Settings'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(items.length, (index) {
          return InkWell(
            onTap: () => _navigateToScreen(index),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: _selectedIndex == index + 4
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index]['icon'] as IconData,
                    color: _selectedIndex == index + 4
                        ? Colors.white
                        : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index]['label'] as String,
                    style: TextStyle(
                      color: _selectedIndex == index + 4
                          ? Colors.white
                          : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  void _navigateToScreen(int index) {
    late Widget screen;
    switch (index) {
      case 0:
        screen = const RobotScreen();
        break;
      case 1:
        screen = const RecordScreen();
        break;
      case 2:
        screen = const MapScreen();
        break;
      case 3:
        return;
    }

    if (screen != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RequestOrderScreen()),
            );
          },
        ),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            subtitle: const Text('Receive notifications from the app'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text('Sound'),
            subtitle: const Text('Play sound for notifications'),
            value: _soundEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _soundEnabled = value;
                    });
                  }
                : null,
            secondary: const Icon(Icons.volume_up),
          ),
          SwitchListTile(
            title: const Text('Vibration'),
            subtitle: const Text('Vibrate for notifications'),
            value: _vibrationEnabled,
            onChanged: _notificationsEnabled
                ? (value) {
                    setState(() {
                      _vibrationEnabled = value;
                    });
                  }
                : null,
            secondary: const Icon(Icons.vibration),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            title: const Text('Theme'),
            subtitle: Text(_selectedTheme),
            leading: const Icon(Icons.palette),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Select Theme'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<String>(
                        title: const Text('System'),
                        value: 'System',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          setState(() {
                            _selectedTheme = value!;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Light'),
                        value: 'Light',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          setState(() {
                            _selectedTheme = value!;
                          });
                          Navigator.pop(context);
                        },
                      ),
                      RadioListTile<String>(
                        title: const Text('Dark'),
                        value: 'Dark',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          setState(() {
                            _selectedTheme = value!;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            title: const Text('Refresh Interval'),
            subtitle: const Text('Auto-refresh data every 30 seconds'),
            leading: const Icon(Icons.refresh),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This feature is coming soon')),
              );
            },
          ),
          ListTile(
            title: const Text('Clear Cache'),
            subtitle: const Text('Clear stored data and cache'),
            leading: const Icon(Icons.delete_outline),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Cache'),
                  content: const Text(
                    'Are you sure you want to clear all cached data?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cache cleared')),
                        );
                      },
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info_outline),
          ),
          ListTile(
            title: const Text('Help & Support'),
            leading: const Icon(Icons.help_outline),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help & Support coming soon')),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: _buildBottomNav(),
      ),
    );
  }
}
