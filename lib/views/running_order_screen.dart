import 'package:flutter/material.dart';
import 'package:pda_handheld/utils/tab_config.dart';
import 'package:pda_handheld/viewmodels/bottom_nav_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';

class RunningOrderScreen extends StatefulWidget {
  const RunningOrderScreen({super.key});

  @override
  State<RunningOrderScreen> createState() => _RunningOrderScreenState();
}

class _RunningOrderScreenState extends State<RunningOrderScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRunningOrders());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BottomNavViewModel>().addListener(_onTabChanged);
    });
  }

  void _onTabChanged() {
    final navVM = context.read<BottomNavViewModel>();

    if (navVM.index == Tabs.running && navVM.previousIndex != Tabs.running) {
      _loadRunningOrders();
    }
  }

  Future<void> _loadRunningOrders() async {
    final orderViewModel = context.read<OrderViewModel>();
    await orderViewModel.fetchRunningOrders();
  }

  void _showCancelMenu(RunningOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.orange),
                title: const Text(
                  'Hủy',
                  style: TextStyle(color: Colors.orange),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cancelOrder(order.taskId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelOrder(String taskId) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this running order?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final orderViewModel = context.read<OrderViewModel>();
    final success = await orderViewModel.cancelRunningOrder(taskId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Order cancelled' : 'Failed to cancel order'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Running')),
      body: Consumer<OrderViewModel>(
        builder: (context, orderViewModel, child) {
          if (orderViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderViewModel.runningOrders.isEmpty) {
            return const Center(child: Text('No running orders'));
          }

          return RefreshIndicator(
            onRefresh: _loadRunningOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: orderViewModel.runningOrders.length,
              itemBuilder: (context, index) {
                final order = orderViewModel.runningOrders[index];

                return GestureDetector(
                  onLongPress: () => _showCancelMenu(order),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.play_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'RUNNING',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Task ID: ${order.taskId}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Task name: ${order.taskName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
