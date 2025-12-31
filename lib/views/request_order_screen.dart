import 'package:flutter/material.dart';
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
  int _selectedIndex = 0;
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

  Widget _buildBottomNav() {
    final items = [
      {'icon': Icons.assignment, 'label': 'Order'},
      {'icon': Icons.inbox, 'label': 'Demand'},
      {'icon': Icons.play_circle, 'label': 'Running'},
      {'icon': Icons.smart_toy, 'label': 'Robot'},
      {'icon': Icons.history, 'label': 'Record'},
      {'icon': Icons.map, 'label': 'Map'},
      {'icon': Icons.person, 'label': 'Profile'},
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
    Widget screen;
    switch (index) {
      case 0:
        return;
      case 1:
        screen = const DemandOrderScreen();
        break;
      case 2:
        screen = const RunningOrderScreen();
        break;
      case 3:
        screen = const RobotScreen();
        break;
      case 4:
        screen = const RecordScreen();
        break;
      case 5:
        screen = const MapScreen();
        break;
      case 6:
        screen = const ProfileScreen();
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
      appBar: AppBar(
        title: const Text('Request order'),
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
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: _buildBottomNav(),
      ),
      floatingActionButton: FloatingActionButton(
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
