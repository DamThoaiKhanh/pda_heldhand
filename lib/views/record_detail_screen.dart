import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/robot_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';

class RecordDetailScreen extends StatefulWidget {
  final Record record;

  const RecordDetailScreen({super.key, required this.record});

  @override
  State<RecordDetailScreen> createState() => _RecordDetailScreenState();
}

class _RecordDetailScreenState extends State<RecordDetailScreen> {
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
    _robotViewModel.clearSelectedRecord(notify: false);
    super.dispose();
  }

  Future<void> _loadRecordDetail() async {
    final robotViewModel = context.read<RobotViewModel>();
    await robotViewModel.fetchRecordDetail(widget.record.taskId);
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
      appBar: AppBar(title: const Text('Record detail')),
      body: Consumer<RobotViewModel>(
        builder: (context, robotViewModel, child) {
          final record = robotViewModel.selectedRecord ?? widget.record;

          if (robotViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                          color: _getStatusColor(record.status),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(record.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            record.status.toUpperCase(),
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
                          _buildDetailRow('Task ID', record.taskId),
                          _buildDetailRow('Task name', record.taskName),
                          _buildDetailRow('Status', record.status),
                          if (record.createdOn != null)
                            _buildDetailRow(
                              'Created on',
                              '${record.createdOn!.day}/${record.createdOn!.month}/${record.createdOn!.year} ${record.createdOn!.hour}:${record.createdOn!.minute.toString().padLeft(2, '0')}',
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (record.robotName != null || record.robotIp != null)
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
                            _buildDetailRow('Robot IP', record.robotIp),
                            _buildDetailRow('Robot name', record.robotName),
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
