import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/views/request_order_screen.dart';
import 'package:pda_handheld/views/demand_order_screen.dart';
import 'package:pda_handheld/views/running_order_screen.dart';
import 'package:pda_handheld/views/robot_screen.dart';
import 'package:pda_handheld/views/record_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRobots());
  }

  Future<void> _loadRobots() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRobots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map')),
      body: Consumer<RobotViewModel>(
        builder: (context, robotViewModel, child) {
          return Stack(
            children: [
              // Map placeholder with grid
              Container(
                color: Colors.grey[200],
                child: CustomPaint(painter: GridPainter(), child: Container()),
              ),
              // Robot positions overlay
              if (robotViewModel.robots.isNotEmpty)
                ...robotViewModel.robots.asMap().entries.map((entry) {
                  final index = entry.key;
                  final robot = entry.value;

                  // Simple positioning logic - in real app, use actual coordinates
                  final left = 50.0 + (index * 80.0) % 300;
                  final top = 100.0 + (index * 100.0) % 400;

                  return Positioned(
                    left: left,
                    top: top,
                    child: _RobotMarker(robot: robot),
                  );
                }),
              // Legend
              Positioned(
                bottom: 80,
                right: 16,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Legend',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _LegendItem(
                          color: Colors.green,
                          label: 'Online & Idle',
                        ),
                        _LegendItem(
                          color: Colors.orange,
                          label: 'Online & Busy',
                        ),
                        _LegendItem(color: Colors.grey, label: 'Offline'),
                      ],
                    ),
                  ),
                ),
              ),
              // Info banner
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Map view is read-only. Robot positions are updated from CORE.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadRobots,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

class _RobotMarker extends StatelessWidget {
  final Robot robot;

  const _RobotMarker({required this.robot});

  Color _getRobotColor() {
    if (!robot.online) return Colors.grey;
    if (robot.currentTask != null) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(robot.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IP: ${robot.ipAddress}'),
                Text('Status: ${robot.status}'),
                Text('Battery: ${robot.battery}%'),
                if (robot.currentTask != null)
                  Text('Task: ${robot.currentTask}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getRobotColor(),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(robot.name, style: const TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double i = 0; i < size.width; i += 50) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i < size.height; i += 50) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
