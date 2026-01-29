import 'package:flutter/material.dart';
import 'package:pda_handheld/utils/tab_config.dart';
import 'package:pda_handheld/viewmodels/bottom_nav_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/views/robot_detail_screen.dart';

class RobotScreen extends StatefulWidget {
  const RobotScreen({super.key});

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRobots());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BottomNavViewModel>().addListener(_onTabChanged);
    });
  }

  void _onTabChanged() {
    final navVM = context.read<BottomNavViewModel>();

    if (navVM.index == Tabs.robot && navVM.previousIndex != Tabs.robot) {
      _loadRobots();
    }
  }

  Future<void> _loadRobots() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRobots();
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

          if (robotViewModel.robotSettingList.isEmpty) {
            return const Center(child: Text('No robots available'));
          }

          return RefreshIndicator(
            onRefresh: _loadRobots,
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: robotViewModel.robotSettingList.length,
              itemBuilder: (context, index) {
                final robot = robotViewModel.robotSettingList[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RobotDetailScreen(robotInfo: robot),
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
                                color: robot.connected
                                    ? Colors.blue
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          robot.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: robot.connected
                                                ? Colors.green
                                                : Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            robot.connected
                                                ? 'Connected'
                                                : 'Disconnected',
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
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${robot.id}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Group: ${robot.group}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Column(
                              //   children: [
                              //     Icon(
                              //       Icons.battery_std,
                              //       color: _getBatteryColor(robot.battery),
                              //     ),
                              //     Text(
                              //       '${robot.battery}%',
                              //       style: TextStyle(
                              //         fontWeight: FontWeight.bold,
                              //         color: _getBatteryColor(robot.battery),
                              //       ),
                              //     ),
                              //   ],
                              // ),
                            ],
                          ),
                          // if (robot.currentTask != null) ...[
                          //   const Divider(height: 24),
                          //   Row(
                          //     children: [
                          //       const Icon(
                          //         Icons.work_outline,
                          //         size: 16,
                          //         color: Colors.blue,
                          //       ),
                          //       const SizedBox(width: 8),
                          //       const Text(
                          //         'Current task: ',
                          //         style: TextStyle(fontWeight: FontWeight.w500),
                          //       ),
                          //       Expanded(
                          //         child: Text(
                          //           robot.currentTask!,
                          //           style: const TextStyle(color: Colors.blue),
                          //         ),
                          //       ),
                          //     ],
                          //   ),
                          //   if (robot.currentTaskId != null) ...[
                          //     const SizedBox(height: 4),
                          //     Text(
                          //       robot.currentTaskId!,
                          //       style: TextStyle(
                          //         fontSize: 12,
                          //         color: Colors.grey[600],
                          //       ),
                          //     ),
                          // ],
                          // ],
                          // const SizedBox(height: 8),
                          // Row(
                          //   children: [
                          //     const Text(
                          //       'Status: ',
                          //       style: TextStyle(fontWeight: FontWeight.w500),
                          //     ),
                          //     Text(
                          //       robot.status,
                          //       style: TextStyle(
                          //         color: robot.status.toLowerCase() == 'idle'
                          //             ? Colors.green
                          //             : Colors.orange,
                          //       ),
                          //     ),
                          //   ],
                          // ),
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
    );
  }
}
