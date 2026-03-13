import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';

class RunningDetailScreen extends StatefulWidget {
  final RunningOrder runningOrder;

  const RunningDetailScreen({super.key, required this.runningOrder});

  @override
  State<RunningDetailScreen> createState() => _RunningDetailScreenState();
}

class _RunningDetailScreenState extends State<RunningDetailScreen> {
  late RobotViewModel _robotViewModel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRecordDetail());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _robotViewModel = context.read<RobotViewModel>();
  }

  @override
  void dispose() {
    // _robotViewModel.clearSelectedRecord(notify: false);
    super.dispose();
  }

  Future<void> _loadRecordDetail() async {
    // final robotViewModel = context.read<RobotViewModel>();
    // await robotViewModel.fetchRecordDetail(widget.runningOrder.taskId);
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
      appBar: AppBar(title: const Text('Running Detail')),
      body: Consumer<RobotViewModel>(
        builder: (context, robotViewModel, child) {
          final runningOrder = widget.runningOrder;

          // if (robotViewModel.isLoading) {
          //   return const Center(child: CircularProgressIndicator());
          // }

          return RefreshIndicator(
            onRefresh: _loadRecordDetail,
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
                          Icons.history,
                          size: 80,
                          color: _getStatusColor('success'),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor('success'),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Running'.toUpperCase(),
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
                            'Task Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildDetailRow('Task ID', runningOrder.taskId),
                          _buildDetailRow('Task name', runningOrder.taskName),
                          _buildDetailRow('Status', 'Running'),
                          if (runningOrder.createdOn != null)
                            _buildDetailRow(
                              'Created on',
                              '${runningOrder.createdOn!.day}/${runningOrder.createdOn!.month}/${runningOrder.createdOn!.year} ${runningOrder.createdOn!.hour}:${runningOrder.createdOn!.minute.toString().padLeft(2, '0')}',
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
                            'Robot Information',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildDetailRow('Robot IP', runningOrder.robotIp),
                          _buildDetailRow('Robot name', runningOrder.robotName),
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
