import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/views/request_order_screen.dart';
import 'package:pda_handheld/views/demand_order_screen.dart';
import 'package:pda_handheld/views/robot_screen.dart';

class RunningOrderScreen extends StatefulWidget {
  const RunningOrderScreen({super.key});

  @override
  State<RunningOrderScreen> createState() => _RunningOrderScreenState();
}

class _RunningOrderScreenState extends State<RunningOrderScreen> {
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRunningOrders());
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

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.assignment, 'label': 'Order'},
      {'icon': Icons.inbox, 'label': 'Demand'},
      {'icon': Icons.play_circle, 'label': 'Running'},
      {'icon': Icons.smart_toy, 'label': 'Robot'},
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
        screen = const RequestOrderScreen();
        break;
      case 1:
        screen = const DemandOrderScreen();
        break;
      case 2:
        return;
      case 3:
        screen = const RobotScreen();
        break;
    }

    if (screen != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: _buildBottomNav(),
      ),
    );
  }
}
