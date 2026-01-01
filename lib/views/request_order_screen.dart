import 'package:flutter/material.dart';
import 'package:pda_handheld/viewmodels/bottom_nav_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/auth_viewmodel.dart';
import 'package:pda_handheld/viewmodels/order_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:pda_handheld/views/new_request_order_screen.dart';
import 'package:pda_handheld/views/demand_order_screen.dart';
import 'package:pda_handheld/views/running_order_screen.dart';
import 'package:pda_handheld/views/robot_screen.dart';
import 'package:pda_handheld/views/record_screen.dart';
import 'package:pda_handheld/views/map_screen.dart';
import 'package:pda_handheld/views/profile_screen.dart';
import 'package:pda_handheld/views/notification_screen.dart';
import 'package:pda_handheld/views/settings_screen.dart';
import 'package:intl/intl.dart';

class RequestOrderScreen extends StatefulWidget {
  const RequestOrderScreen({super.key});

  @override
  State<RequestOrderScreen> createState() => _RequestOrderScreenState();
}

class _RequestOrderScreenState extends State<RequestOrderScreen> {
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadOrders());
  }

  void _loadOrders() {
    final authViewModel = context.read<AuthViewModel>();
    final orderViewModel = context.read<OrderViewModel>();
    if (authViewModel.user != null) {
      orderViewModel.loadRequestOrders(authViewModel.user!.account);
    }
  }

  void _showMenu(RequestOrder order) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _editOrder(order);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteOrder(order.id);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _editOrder(RequestOrder order) {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => NewRequestOrderScreen(existingOrder: order),
          ),
        )
        .then((_) => _loadOrders());
  }

  void _deleteOrder(String orderId) {
    final authViewModel = context.read<AuthViewModel>();
    final orderViewModel = context.read<OrderViewModel>();
    if (authViewModel.user != null) {
      orderViewModel.deleteRequestOrder(authViewModel.user!.account, orderId);
    }
  }

  Future<void> _sendOrder(RequestOrder order) async {
    final authViewModel = context.read<AuthViewModel>();
    final orderViewModel = context.read<OrderViewModel>();
    final success = await orderViewModel.sendRequestOrder(order);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Order sent successfully' : 'Failed to send order',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        setState(() {
          _selectedOrderId = null;
        });

        orderViewModel.deleteRequestOrder(
          authViewModel.user!.account,
          order.id,
        );
      }
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
        title: const Text('Request Order'),
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
          if (orderViewModel.requestOrders.isEmpty) {
            return const Center(
              child: Text('No request orders. Tap + to add new.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orderViewModel.requestOrders.length,
            itemBuilder: (context, index) {
              final order = orderViewModel.requestOrders[index];
              final isSelected = order.id == _selectedOrderId;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedOrderId = isSelected ? null : order.id;
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
                        Text('Priority: ${order.priority}'),
                        if (isSelected) ...[
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _sendOrder(order),
                            child: const Text('Send'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "request_order_fab",
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const NewRequestOrderScreen(),
                ),
              )
              .then((_) => _loadOrders());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
