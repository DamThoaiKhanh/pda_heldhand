import 'package:flutter/material.dart';
import 'package:pda_handheld/utils/tab_config.dart';
import 'package:pda_handheld/viewmodels/bottom_nav_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/views/record_detail_screen.dart';

class RecordScreen extends StatefulWidget {
  const RecordScreen({super.key});

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  late BottomNavViewModel _bottomNavViewModel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRecords());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BottomNavViewModel>().addListener(_onTabChanged);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bottomNavViewModel = context.read<BottomNavViewModel>();
  }

  @override
  void dispose() {
    _bottomNavViewModel.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    final navVM = context.read<BottomNavViewModel>();

    if (navVM.index == Tabs.record && navVM.previousIndex != Tabs.record) {
      _loadRecords();
    }
  }

  Future<void> _loadRecords() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRecords();
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
      appBar: AppBar(title: const Text('Record')),
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
    );
  }
}
