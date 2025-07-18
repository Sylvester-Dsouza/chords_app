import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';
import '../config/theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  bool _groupByDate = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _notificationService.getNotificationHistory();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading notifications: $e');
    }
  }

  String _formatDate(String dateString) {
    final DateTime date = DateTime.parse(dateString);
    final DateTime now = DateTime.now();
    final DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
    final DateFormat timeFormat = DateFormat.jm();
    final DateFormat dateFormat = DateFormat('MMM d, yyyy');

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${timeFormat.format(date)}';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday, ${timeFormat.format(date)}';
    } else {
      return dateFormat.format(date);
    }
  }

  Widget _buildNotificationItem(dynamic notification) {
    final notificationData = notification['notification'];
    final bool isRead = notification['status'] != 'DELIVERED';
    final String title = notificationData['title'] ?? 'Notification';
    final String body = notificationData['body'] ?? '';
    final String date = _formatDate(notification['createdAt']);
    final String notificationId = notification['notificationId'];

    // Determine icon based on notification type
    IconData iconData;
    Color iconColor;

    switch (notificationData['type']) {
      case 'SONG_ADDED':
        iconData = Icons.music_note;
        iconColor = Colors.green;
        break;
      case 'SONG_REQUEST_COMPLETED':
        iconData = Icons.check_circle;
        iconColor = Colors.blue;
        break;
      case 'NEW_FEATURE':
        iconData = Icons.new_releases;
        iconColor = Colors.orange;
        break;
      case 'SUBSCRIPTION':
        iconData = Icons.card_membership;
        iconColor = Colors.purple;
        break;
      case 'PROMOTION':
        iconData = Icons.local_offer;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Theme.of(context).colorScheme.primary;
    }

    return InkWell(
      onTap: () {
        // Mark as clicked if not already read
        if (!isRead) {
          _notificationService.markNotificationAsClicked(notificationId);

          // Update the local state
          setState(() {
            notification['status'] = 'CLICKED';
          });
        }

        // Handle notification click based on type
        // This would navigate to the appropriate screen based on the notification data
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isRead ? Colors.transparent : Colors.grey.withAlpha(25),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withAlpha(50),
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color.fromARGB(
                  25,
                  iconColor.r.toInt(),
                  iconColor.g.toInt(),
                  iconColor.b.toInt(),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(
                iconData,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[300],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        backgroundColor: AppTheme.appBar,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'group':
                  setState(() {
                    _groupByDate = !_groupByDate;
                  });
                  break;
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'clear_all':
                  _clearAllNotifications();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'group',
                child: Row(
                  children: [
                    Icon(
                      _groupByDate ? Icons.view_list : Icons.view_agenda,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _groupByDate ? 'Ungroup' : 'Group by Date',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Row(
                  children: [
                    Icon(
                      Icons.mark_email_read,
                      color: Colors.white70,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Mark All Read',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(
                      Icons.clear_all,
                      color: Colors.red,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We\'ll notify you when there\'s something new',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadNotifications,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      return _buildNotificationItem(_notifications[index]);
                    },
                  ),
                ),
      // Bottom navigation bar removed from inner screens
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      // Mark all unread notifications as read
      for (final notification in _notifications) {
        if (notification['status'] == 'DELIVERED') {
          await _notificationService.markNotificationAsRead(notification['notificationId']);
          notification['status'] = 'READ';
        }
      }

      setState(() {
        // UI will update automatically
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Clear All Notifications',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _notifications.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications cleared'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}
