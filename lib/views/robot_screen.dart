import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/views/request_order_screen.dart';
import 'package:pda_handheld/views/demand_order_screen.dart';
import 'package:pda_handheld/views/running_order_screen.dart';
import 'package:pda_handheld/views/robot_detail_screen.dart';

class RobotScreen extends StatefulWidget {
  const RobotScreen({super.key});

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRobots());
  }

  Future<void> _loadRobots() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRobots();
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.assignment, 'label': 'Order'},
      {'icon': Icons.inbox, 'label': 'Demand'},
      {'icon': Icons.play_circle, 'label': 'Running'},
      {'icon': Icons.smart_toy, 'label': 'Robot'},
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
                color: _selectedIndex == index
                    ? Theme.of(context).primaryColor
                    : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[index]['icon'] as IconData,
                    color: _selectedIndex == index ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[index]['label'] as String,
                    style: TextStyle(
                      color: _selectedIndex == index
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
        screen = const RequestOrderScreen();
        break;
      case 1:
        screen = const DemandOrderScreen();
        break;
      case 2:
        screen = const RunningOrderScreen();
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

  Color _getBatteryColor(int battery) {
    if (battery > 60) return Colors.green;
    if (battery > 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Robot')),
      body: Consumer<RobotViewModel>(
        builder: (context, robotViewModel, child) {
          if (robotViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (robotViewModel.robots.isEmpty) {
            return const Center(child: Text('No robots available'));
          }

          return RefreshIndicator(
            onRefresh: _loadRobots,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: robotViewModel.robots.length,
              itemBuilder: (context, index) {
                final robot = robotViewModel.robots[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RobotDetailScreen(robot: robot),
                      ),
                    );
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.smart_toy,
                                size: 40,
                                color: robot.online ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          robot.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: robot.online
                                                ? Colors.green
                                                : Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            robot.online ? 'Online' : 'Offline',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'IP Address: ${robot.ipAddress}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Icon(
                                    Icons.battery_std,
                                    color: _getBatteryColor(robot.battery),
                                  ),
                                  Text(
                                    '${robot.battery}%',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _getBatteryColor(robot.battery),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          if (robot.currentTask != null) ...[
                            const Divider(height: 24),
                            Row(
                              children: [
                                const Icon(
                                  Icons.work_outline,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Current task: ',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Expanded(
                                  child: Text(
                                    robot.currentTask!,
                                    style: const TextStyle(color: Colors.blue),
                                  ),
                                ),
                              ],
                            ),
                            if (robot.currentTaskId != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                robot.currentTaskId!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text(
                                'Status: ',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                robot.status,
                                style: TextStyle(
                                  color: robot.status.toLowerCase() == 'idle'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
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
