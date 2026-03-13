import 'package:flutter/material.dart';
import 'package:pda_handheld/utils/tab_config.dart';
import 'package:pda_handheld/viewmodels/bottom_nav_viewmodel.dart';
import 'package:pda_handheld/views/notification_screen.dart';
import 'package:pda_handheld/views/running_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';

class RunningOrderScreen extends StatefulWidget {
  const RunningOrderScreen({super.key});

  @override
  State<RunningOrderScreen> createState() => _RunningOrderScreenState();
}

class _RunningOrderScreenState extends State<RunningOrderScreen> {
  BottomNavViewModel? _bottomNavViewModel;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadRunningOrders());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _bottomNavViewModel = context.read<BottomNavViewModel>();
      _bottomNavViewModel!.addListener(_onTabChanged);
    });
  }

  @override
  void dispose() {
    _bottomNavViewModel?.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (!mounted) return;
    final navVM = _bottomNavViewModel;
    if (navVM == null) return;

    if (navVM.index == Tabs.running && navVM.previousIndex != Tabs.running) {
      _loadRunningOrders();
    }
  }

  Future<void> _loadRunningOrders() async {
    if (!mounted) return;
    final orderViewModel = context.read<OrderViewModel>();
    await orderViewModel.fetchRunningOrders();
  }

  void _showModalBottomMenu(RunningOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.list_rounded, color: Colors.orange),
                title: const Text(
                  'Detail Order',
                  // style: TextStyle(color: Colors.orange),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RunningDetailScreen(runningOrder: order),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text(
                  'Cancel Order',
                  // style: TextStyle(color: Colors.orange),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _cancelOrderConfirm(order.taskId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _cancelOrderConfirm(String taskId) async {
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

  void openSettingsTab(BuildContext context) {
    Navigator.popUntil(context, (route) => route.isFirst);
    context.read<BottomNavViewModel>().setIndex(Tabs.settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Running Orders'),
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
                  onTap: () => _showModalBottomMenu(order),
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
