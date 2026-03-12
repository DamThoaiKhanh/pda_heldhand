import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pda_handheld/providers/websocket_provider.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';

class RobotDetailScreen extends StatefulWidget {
  final RobotInfo robotInfo;

  const RobotDetailScreen({super.key, required this.robotInfo});

  @override
  State<RobotDetailScreen> createState() => _RobotDetailScreenState();
}

class _RobotDetailScreenState extends State<RobotDetailScreen> {
  late RobotViewModel _robotViewModel;

  Timer? _debugTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRobotDetail());

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _startDebugSend();
    // });

    _startDebugSend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _robotViewModel = context.read<RobotViewModel>();
  }

  @override
  void dispose() {
    _debugTimer?.cancel(); // ✅ stop sending debug commands
    _robotViewModel.clearSelectedRobot(notify: false);
    super.dispose();
  }

  void _startDebugSend() {
    final robotProvider = context.read<WebsocketProvider>();

    // Prevent multiple timers
    _debugTimer?.cancel();

    _debugTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      robotProvider.sendCommand(1006, data: {"robotId": widget.robotInfo.id});

      // debugPrint("Sent WS command 1004 for robot ${widget.robotInfo.id}");
    });
  }

  double radToDeg(double radians) {
    return radians * 180 / math.pi;
  }

  Widget _buildWsDebugCard(WebsocketProvider robotProvider) {
    final lastCommand = robotProvider.robotData["lastCommand"];
    final lastData = robotProvider.robotData["lastData"];

    return Card(
      color: Colors.black,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "WebSocket Debug (Last Received)",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text("State: ", style: TextStyle(color: Colors.white70)),
                Text(
                  robotProvider.connectionState.toString(),
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "command: ${lastCommand ?? 'N/A'}",
              style: const TextStyle(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "data: ${lastData ?? 'N/A'}",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRobotDetail() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRobotDetail(widget.robotInfo.id);
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
    if (battery > 30) return Colors.green;
    if (battery > 20) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final robotProvider = context.watch<WebsocketProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Robot detail')),
      body: Consumer<RobotViewModel>(
        builder: (context, robotViewModel, child) {
          final robotStatus =
              // robotViewModel.selectedRobotStatus ??
              robotProvider.getRobotStatus(widget.robotInfo.id) ??
              RobotStatus(
                ipAddress: "",
                id: "zz",
                status: "",
                online: false,
                battery: 0,
                chargingMode: ChargingMode.free,
                taskState: TaskRunningState.stopped,
                x: 0,
                y: 0,
                theta: 0,
              );
          final robotInfo = widget.robotInfo;
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
                          Icons.garage_rounded,
                          size: 80,
                          color: robotInfo.connected
                              ? Colors.blue
                              : Colors.grey,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: robotInfo.connected
                                ? Colors.green
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            robotInfo.connected ? 'CONNECTED' : 'DISCONNECTED',
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
                          _buildDetailRow('Name', robotInfo.name),
                          _buildDetailRow('ID', robotInfo.id),
                          _buildDetailRow('Group', robotInfo.group),
                          _buildDetailRow('IP Address', robotInfo.ipAddress),
                          _buildDetailRow('MAC', robotInfo.mac),
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
                            'Localization',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          ...[
                            _buildDetailRow(
                              'Position X',
                              robotStatus.x!.toStringAsFixed(3) + " m",
                            ),
                            _buildDetailRow(
                              'Position Y',
                              robotStatus.y!.toStringAsFixed(3) + " m",
                            ),
                            _buildDetailRow(
                              'Orientation',
                              "${(radToDeg(robotStatus.theta ?? 0)).toStringAsFixed(1)} deg",
                            ),
                            _buildDetailRow(
                              'Confidence',
                              "${((robotStatus.confidence ?? 0) * 100).toStringAsFixed(1)} %",
                            ),
                          ],
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
                                              value: robotStatus.battery / 100,
                                              backgroundColor: Colors.grey[300],
                                              color: _getBatteryColor(
                                                robotStatus.battery,
                                              ),
                                              minHeight: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${robotStatus.battery}%',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _getBatteryColor(
                                                robotStatus.battery,
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
                            'Voltage',
                            robotStatus.voltage != null
                                ? '${robotStatus.voltage!.toStringAsFixed(2)} V'
                                : 'N/A',
                          ),
                          _buildDetailRow(
                            'Current',
                            robotStatus.current != null
                                ? '${robotStatus.current!.toStringAsFixed(2)} A'
                                : 'N/A',
                          ),
                          _buildDetailRow(
                            'Charging',
                            robotStatus.chargingMode.name.toUpperCase(),
                          ),
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
                            'Task Status',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          ...[
                            _buildDetailRow(
                              'Task ID',
                              robotStatus.currentTaskId,
                            ),
                            _buildDetailRow(
                              'Task Name',
                              robotStatus.currentTask,
                            ),
                            _buildDetailRow(
                              'Task State',
                              robotStatus.taskState.name.toUpperCase(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _buildWsDebugCard(robotProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
