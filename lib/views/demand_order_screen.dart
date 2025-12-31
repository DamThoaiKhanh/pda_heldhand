import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/views/request_order_screen.dart';
import 'package:pda_handheld/views/running_order_screen.dart';
import 'package:pda_handheld/views/robot_screen.dart';
import 'package:intl/intl.dart';

class DemandOrderScreen extends StatefulWidget {
  const DemandOrderScreen({super.key});

  @override
  State<DemandOrderScreen> createState() => _DemandOrderScreenState();
}

class _DemandOrderScreenState extends State<DemandOrderScreen> {
  int _selectedIndex = 1;
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadDemandOrders());
  }

  Future<void> _loadDemandOrders() async {
    final orderViewModel = context.read<OrderViewModel>();
    await orderViewModel.fetchDemandOrders();
  }

  void _showMenu(DemandOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteOrder(order.taskId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmOrder(String taskId) async {
    final orderViewModel = context.read<OrderViewModel>();
    final success = await orderViewModel.confirmDemandOrder(taskId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Order confirmed' : 'Failed to confirm order',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        setState(() {
          _selectedOrderId = null;
        });
      }
    }
  }

  Future<void> _deleteOrder(String taskId) async {
    final orderViewModel = context.read<OrderViewModel>();
    final success = await orderViewModel.deleteDemandOrder(taskId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Order deleted' : 'Failed to delete order'),
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
        return; // no navigation
      case 2:
        screen = const RunningOrderScreen();
        break;
      case 3:
        screen = const RobotScreen();
        break;
      default:
        return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demand order')),
      body: Consumer<OrderViewModel>(
        builder: (context, orderViewModel, child) {
          if (orderViewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (orderViewModel.demandOrders.isEmpty) {
            return const Center(child: Text('No demand orders available'));
          }

          return RefreshIndicator(
            onRefresh: _loadDemandOrders,
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: orderViewModel.demandOrders.length,
              itemBuilder: (context, index) {
                final order = orderViewModel.demandOrders[index];
                final isSelected = order.taskId == _selectedOrderId;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedOrderId = isSelected ? null : order.taskId;
                    });
                  },
                  onLongPress: () => _showMenu(order),
                  child: Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Task name: ${order.taskName}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Task ID: ${order.taskId}'),
                          Text(
                            'Create at: ${DateFormat('MM/dd/yyyy h:mm a').format(order.createdAt)}',
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => _confirmOrder(order.taskId),
                              child: const Text('Confirm'),
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
