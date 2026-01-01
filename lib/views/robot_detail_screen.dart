import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';

class RobotDetailScreen extends StatefulWidget {
  final Robot robot;

  const RobotDetailScreen({super.key, required this.robot});

  @override
  State<RobotDetailScreen> createState() => _RobotDetailScreenState();
}

class _RobotDetailScreenState extends State<RobotDetailScreen> {
  late RobotViewModel _robotViewModel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRobotDetail());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _robotViewModel = context.read<RobotViewModel>();
  }

  @override
  void dispose() {
    _robotViewModel.clearSelectedRobot(notify: false);
    super.dispose();
  }

  Future<void> _loadRobotDetail() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRobotDetail(widget.robot.ipAddress);
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A', style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Color _getBatteryColor(int battery) {
    if (battery > 60) return Colors.green;
    if (battery > 30) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Robot detail')),
      body: Consumer<RobotViewModel>(
        builder: (context, robotViewModel, child) {
          final robot = robotViewModel.selectedRobot ?? widget.robot;

          if (robotViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _loadRobotDetail,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 80,
                          color: robot.online ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: robot.online ? Colors.green : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            robot.online ? 'ONLINE' : 'OFFLINE',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Basic Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildDetailRow('IP Address', robot.ipAddress),
                          _buildDetailRow('Name', robot.name),
                          _buildDetailRow('ID', robot.id),
                          _buildDetailRow('Status', robot.status),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Battery & Power',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 120,
                                  child: Text(
                                    'Battery',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: LinearProgressIndicator(
                                              value: robot.battery / 100,
                                              backgroundColor: Colors.grey[300],
                                              color: _getBatteryColor(
                                                robot.battery,
                                              ),
                                              minHeight: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${robot.battery}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _getBatteryColor(
                                                robot.battery,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildDetailRow(
                            'Charging',
                            robot.charging == true ? 'Yes' : 'No',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (robot.currentTask != null || robot.confidence != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Additional Info',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(),
                            if (robot.currentTask != null) ...[
                              _buildDetailRow(
                                'Current Task',
                                robot.currentTask,
                              ),
                              _buildDetailRow('Task ID', robot.currentTaskId),
                            ],
                            if (robot.confidence != null)
                              _buildDetailRow(
                                'Confidence',
                                robot.confidence!.toStringAsFixed(2),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
