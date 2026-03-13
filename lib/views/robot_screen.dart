import 'package:flutter/material.dart';
import 'package:pda_handheld/providers/websocket_provider.dart';
import 'package:pda_handheld/utils/tab_config.dart';
import 'package:pda_handheld/viewmodels/bottom_nav_viewmodel.dart';
import 'package:pda_handheld/views/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/views/robot_detail_screen.dart';

class RobotScreen extends StatefulWidget {
  const RobotScreen({super.key});

  @override
  State<RobotScreen> createState() => _RobotScreenState();
}

class _RobotScreenState extends State<RobotScreen> {
  BottomNavViewModel? _bottomNavViewModel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRobotList());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _bottomNavViewModel = context.read<BottomNavViewModel>();
      _bottomNavViewModel!.addListener(_onTabChanged);
    });
  }

  @override
  void dispose() {
    _bottomNavViewModel?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    final navVM = _bottomNavViewModel;
    if (navVM == null) return;

    if (navVM.index == Tabs.robot && navVM.previousIndex != Tabs.robot) {
      _loadRobotList();
    }
  }

  Future<void> _loadRobotList() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRobots();

    robotViewModel.robotSettingList.forEach((robot) {
      context.read<WebsocketProvider>().setRobotConnection(
        robot.id,
        robot.connected,
      );
    });
  }

  Color _getBatteryColor(int battery) {
    if (battery > 30) return Colors.green;
    if (battery > 20) return Colors.orange;
    return Colors.red;
  }

  void openSettingsTab(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    context.read<BottomNavViewModel>().setIndex(Tabs.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Robots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
            onSelected: (value) {
              if (value == 'settings') {
                openSettingsTab(context);
              }
            },
          ),
        ],
      ),
      body: Consumer2<RobotViewModel, WebsocketProvider>(
        builder: (context, robotViewModel, websocketProvider, child) {
          if (robotViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (robotViewModel.robotSettingList.isEmpty) {
            return RefreshIndicator(
              onRefresh: _loadRobotList,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: const Center(child: Text('No robots available')),
                    ),
                  );
                },
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadRobotList,
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: robotViewModel.robotSettingList.length,
              itemBuilder: (context, index) {
                final robot = robotViewModel.robotSettingList[index];
                final isConnected = websocketProvider.getRobotConnection(
                  robot.id,
                );

                final battery =
                    websocketProvider.getRobotStatus(robot.id)?.battery ?? 0;

                return GestureDetector(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RobotDetailScreen(robotInfo: robot),
                      ),
                    );

                    await _loadRobotList();
                  },
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.garage_rounded,
                                size: 40,
                                color: isConnected ? Colors.blue : Colors.grey,
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
                                            color: isConnected
                                                ? Colors.green
                                                : Colors.grey,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            isConnected
                                                ? 'Connected'
                                                : 'Disconnected',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.battery_std,
                                              color: _getBatteryColor(battery),
                                            ),
                                            Text(
                                              '${battery}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: _getBatteryColor(
                                                  battery,
                                                ),
                                              ),
                                            ),
                                          ],
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
