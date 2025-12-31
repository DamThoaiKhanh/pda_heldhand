import 'package:flutter/material.dart';
import 'package:pda_handheld/viewmodels/notification_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/auth_viewmodel.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';

class NewRequestOrderScreen extends StatefulWidget {
  final RequestOrder? existingOrder;

  const NewRequestOrderScreen({super.key, this.existingOrder});

  @override
  State<NewRequestOrderScreen> createState() => _NewRequestOrderScreenState();
}

class _NewRequestOrderScreenState extends State<NewRequestOrderScreen> {
  String? _selectedTaskId;
  String? _selectedTaskName;
  String? _priority;
  bool _isLoading = true;

  final List<String> priorities = List.generate(
    11,
    (index) => (index).toString(),
  );

  @override
  void initState() {
    super.initState();

    Future.microtask(() => _loadTasks());

    if (widget.existingOrder != null) {
      _selectedTaskId = widget.existingOrder!.taskId;
      _selectedTaskName = widget.existingOrder!.taskName;
      _priority = widget.existingOrder!.priority;
    }
  }

  Future<void> _loadTasks() async {
    final orderViewModel = context.read<OrderViewModel>();
    await orderViewModel.fetchAvailableTasks();
    setState(() {
      _isLoading = false;
    });
  }

  void _save() async {
    if (_selectedTaskId == null || _selectedTaskName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a task')));
      return;
    }

    final authViewModel = context.read<AuthViewModel>();
    final orderViewModel = context.read<OrderViewModel>();

    if (authViewModel.user == null) return;

    if (widget.existingOrder != null) {
      // Update existing order
      final updatedOrder = RequestOrder(
        id: widget.existingOrder!.id,
        taskId: _selectedTaskId!,
        taskName: _selectedTaskName!,
        priority: _priority ?? '0',
        createdAt: widget.existingOrder!.createdAt,
      );
      await orderViewModel.updateRequestOrder(
        authViewModel.user!.account,
        widget.existingOrder!.id,
        updatedOrder,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order updated')));
      }
    } else {
      // Create new order
      final newOrder = RequestOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        taskId: _selectedTaskId!,
        taskName: _selectedTaskName!,
        priority: _priority ?? '0',
        createdAt: DateTime.now(),
      );
      await orderViewModel.addRequestOrder(
        authViewModel.user!.account,
        newOrder,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Order created')));

        final noti = context.read<NotificationViewModel>();
        noti.addNotification(
          AppNotification(
            id: '1',
            title: 'New Request Order',
            message: 'A new request order has been created.',
            type: NotificationType.info,
            createdAt: DateTime.now(),
          ),
        );
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  void _clear() {
    setState(() {
      _selectedTaskId = null;
      _selectedTaskName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingOrder != null ? 'Edit request' : 'New request',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<OrderViewModel>(
              builder: (context, orderViewModel, child) {
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Task selection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedTaskId,
                        decoration: const InputDecoration(
                          labelText: 'Select Task',
                          border: OutlineInputBorder(),
                        ),
                        items: orderViewModel.availableTasks.map((task) {
                          return DropdownMenuItem(
                            value: task.taskId,
                            child: Text(task.taskId),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedTaskId = value;
                            _selectedTaskName = orderViewModel.availableTasks
                                .firstWhere((t) => t.taskId == value)
                                .taskName;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _priority,
                        decoration: const InputDecoration(
                          labelText: 'Select Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: priorities.map((p) {
                          return DropdownMenuItem<String>(
                            value: p,
                            child: Text(p),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _priority = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedTaskName != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Task Name: $_selectedTaskName',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Task ID: $_selectedTaskId',
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Priority: $_priority',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'SAVE',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _clear,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'CLEAR',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
