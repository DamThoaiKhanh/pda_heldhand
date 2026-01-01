import 'package:flutter/material.dart';
import 'package:pda_handheld/utils/tab_config.dart';
import 'package:pda_handheld/viewmodels/bottom_nav_viewmodel.dart';
import 'package:pda_handheld/views/notification_screen.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:intl/intl.dart';

class DemandOrderScreen extends StatefulWidget {
  const DemandOrderScreen({super.key});

  @override
  State<DemandOrderScreen> createState() => _DemandOrderScreenState();
}

class _DemandOrderScreenState extends State<DemandOrderScreen> {
  late BottomNavViewModel _bottomNavViewModel;
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();

    Future.microtask(() => _loadDemandOrders());

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

    if (navVM.index == Tabs.demand && navVM.previousIndex != Tabs.demand) {
      _loadDemandOrders();
    }
  }

  Future<void> _loadDemandOrders() async {
    await context.read<OrderViewModel>().fetchDemandOrders();
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

  void openSettingsTab(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    context.read<BottomNavViewModel>().setIndex(7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demand Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              );
            },
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
            ],
            onSelected: (value) {
              if (value == 'settings') {
                openSettingsTab(context);
              }
            },
          ),
        ],
      ),
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
    );
  }
}
