import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/views/record_detail_screen.dart';
import 'package:pda_handheld/views/request_order_screen.dart';
import 'package:pda_handheld/views/demand_order_screen.dart';
import 'package:pda_handheld/views/running_order_screen.dart';
import 'package:pda_handheld/views/robot_screen.dart';
import 'package:pda_handheld/views/map_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  int _selectedIndex = 4;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRecords());
  }

  Future<void> _loadRecords() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRecords();
  }

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.inbox, 'label': 'Demand'},
      {'icon': Icons.play_circle, 'label': 'Running'},
      {'icon': Icons.smart_toy, 'label': 'Robot'},
      {'icon': Icons.history, 'label': 'Record'},
      {'icon': Icons.map, 'label': 'Map'},
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
        screen = const DemandOrderScreen();
        break;
      case 1:
        screen = const RunningOrderScreen();
        break;
      case 2:
        screen = const RobotScreen();
        break;
      case 3:
        return;
      case 4:
        screen = const MapScreen();
        break;
    }

    if (screen != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'finish':
      case 'completed':
      case 'success':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      case 'cancelled':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Record'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const RequestOrderScreen()),
            );
          },
        ),
      ),
      body: Consumer<RobotViewModel>(
        builder: (context, robotViewModel, child) {
          if (robotViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (robotViewModel.records.isEmpty) {
            return const Center(child: Text('No records available'));
          }

          return RefreshIndicator(
            onRefresh: _loadRecords,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: robotViewModel.records.length,
              itemBuilder: (context, index) {
                final record = robotViewModel.records[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecordDetailScreen(record: record),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Task ID: ${record.taskId}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Task name: ${record.taskName}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(record.status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  record.status,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (record.robotName != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.smart_toy,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  record.robotName!,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                          if (record.createdOn != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${record.createdOn!.day}/${record.createdOn!.month}/${record.createdOn!.year} ${record.createdOn!.hour}:${record.createdOn!.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
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
