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
    // final robotViewModel = context.read<RobotViewModel>();
    // await robotViewModel.fetchRobotDetail(widget.robotInfo.id);

    final robotProvider = context.read<WebsocketProvider>();
    robotProvider.sendCommand(1006, data: {"robotId": widget.robotInfo.id});

    // Update robot connection status based on initial data (since WebSocket updates may not come immediately)
    robotProvider.setRobotConnection(
      widget.robotInfo.id,
      widget.robotInfo.connected,
    );
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
              robotProvider.getRobotStatus(widget.robotInfo.id) ??
              RobotStatus.makeOffline();
          final robotInfo = widget.robotInfo;
          final connectionStatus = robotProvider.getRobotConnection(
            widget.robotInfo.id,
          );
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        StatusHighlight(
                          label: 'CONNECTION',
                          icon: connectionStatus
                              ? Icons.wifi
                              : Icons.wifi_off_outlined,
                          // icon: Icons.wifi,
                          iconBgColor: Color(0xFF1F2A44),
                          iconColor: connectionStatus
                              ? Colors.white
                              : Colors.redAccent,
                        ),
                        SizedBox(width: 16),
                        StatusHighlight(
                          label: 'AUTO MODE',
                          // icon: Icons.hdr_auto,
                          icon: robotStatus.mode == RobotMode.auto
                              ? Icons.check_circle_outline_rounded
                              : Icons.radio_button_unchecked,
                          iconBgColor: Color(0xFF1F2A44),
                          iconColor: robotStatus.mode == RobotMode.auto
                              ? Colors.green
                              : Colors.white,
                        ),
                        SizedBox(width: 16),
                        StatusHighlight(
                          label: 'EMERGENCY',
                          icon: robotStatus.emergency
                              ? Icons.lock
                              : Icons.lock_open,
                          iconBgColor: Color(0xFF1F2A44),
                          iconColor: robotStatus.emergency
                              ? Colors.red
                              : Colors.white,
                        ),
                      ],
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

class StatusHighlight extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;

  const StatusHighlight({
    super.key,
    required this.label,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: Icon(icon, size: 38, color: iconColor)),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
