import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pda_handheld/viewmodels/notification_viewmodel.dart';
import 'package:pda_handheld/models/models.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    final notificationViewModel = context.read<NotificationViewModel>();
    await notificationViewModel.loadNotifications();
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.warning:
        return Colors.orange;
      case NotificationType.error:
        return Colors.red;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.info:
        return Icons.info_outline;
      case NotificationType.warning:
        return Icons.warning_amber_outlined;
      case NotificationType.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
        actions: [
          Consumer<NotificationViewModel>(
            builder: (context, notificationViewModel, child) {
              if (notificationViewModel.isSelectionMode) {
                return Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        notificationViewModel.isSelectAll
                            ? notificationViewModel.unselectAll()
                            : notificationViewModel.selectAll();
                      },
                      child: Text(
                        notificationViewModel.isSelectAll
                            ? 'Unselect all'
                            : 'Select all',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed:
                          notificationViewModel.selectedNotifications.isEmpty
                          ? null
                          : () async {
                              await notificationViewModel.deleteSelected();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notifications deleted'),
                                  ),
                                );
                              }
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        notificationViewModel.toggleSelectionMode();
                      },
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<NotificationViewModel>(
        builder: (context, notificationViewModel, child) {
          if (notificationViewModel.notifications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: notificationViewModel.notifications.length,
            itemBuilder: (context, index) {
              final notification = notificationViewModel.notifications[index];
              final isSelected = notificationViewModel.selectedNotifications
                  .contains(notification.id);

              return GestureDetector(
                onLongPress: () {
                  if (!notificationViewModel.isSelectionMode) {
                    notificationViewModel.toggleSelectionMode();
                  }
                  notificationViewModel.toggleNotificationSelection(
                    notification.id,
                  );
                },
                onTap: () {
                  if (notificationViewModel.isSelectionMode) {
                    notificationViewModel.toggleNotificationSelection(
                      notification.id,
                    );
                  }
                },
                child: Card(
                  color: isSelected ? Colors.blue.shade50 : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (notificationViewModel.isSelectionMode)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                notificationViewModel
                                    .toggleNotificationSelection(
                                      notification.id,
                                    );
                              },
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getNotificationColor(
                              notification.type,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.type),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification.message,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat(
                                  'MMM dd, yyyy h:mm a',
                                ).format(notification.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!notificationViewModel.isSelectionMode)
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () async {
                              await notificationViewModel.deleteNotification(
                                notification.id,
                              );
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Notification deleted'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<NotificationViewModel>(
        builder: (context, notificationViewModel, child) {
          if (notificationViewModel.notifications.isEmpty) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            heroTag: "NotificationClearAllFAB",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear All'),
                  content: const Text(
                    'Are you sure you want to delete all notifications?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await notificationViewModel.clearAll();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('All notifications cleared'),
                            ),
                          );
                        }
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              );
            },
            label: const Text('Clear All'),
            icon: const Icon(Icons.delete_sweep),
          );
        },
      ),
    );
  }
}
