import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:zyvionix_pos/constants/api_constants.dart';
import 'package:zyvionix_pos/controllers/language_controller.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final String baseUrl = "${ApiConstants.baseUrl}/notifications";
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/${widget.userId}'));

      print('Response status code for notification api ${response.statusCode}');
      print(
        'Response bodyyyyyyyyyyyy code for notification api ${response.body}',
      );

      if (response.statusCode == 200) {
        setState(() {
          notifications = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteNotification(String id, int index) async {
    // Optimistically remove from UI
    final removedItem = notifications.removeAt(index);
    setState(() {});

    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));

      print(
        'Response status code for delete notifications ${response.statusCode}',
      );

      print('Response bodyyyyyyyyyy for delete notifications ${response.body}');

      if (response.statusCode == 200) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: Colors.red,
              content: Text('Notification Deleted Successfully'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Revert on failure
        setState(() {
          notifications.insert(index, removedItem);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete notification'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error deleting: $e');

      // Revert on failure
      if (mounted) {
        setState(() {
          notifications.insert(index, removedItem);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Future<void> _deleteNotification(String id, int index) async {
  //   try {
  //     // Optimistically remove from UI
  //     final removedItem = notifications.removeAt(index);
  //     setState(() {});

  //     final response = await http.delete(Uri.parse('$baseUrl/$id'));

  //     print(
  //       'Response status code for delete notifications ${response.statusCode}',
  //     );

  //     print('Response bodyyyyyyyyyy for delete notifications ${response.body}');

  //     if (response.statusCode != 200) {
  //       // Revert on failure
  //       setState(() => notifications.insert(index, removedItem));
  //       throw Exception('Failed to delete');
  //     }
  //   } catch (e) {
  //     print('Error deleting: $e');
  //   }
  // }

  Future<void> _clearAllNotifications() async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to delete all your notifications?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => isLoading = true);
      try {
        final response = await http.delete(
          Uri.parse('$baseUrl/all/${widget.userId}'),
        );
        if (response.statusCode == 200) {
          setState(() {
            notifications.clear();
            isLoading = false;
          });
        } else {
          throw Exception('Failed to clear all');
        }
      } catch (e) {
        print('Error clearing notifications: $e');
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('useriddddddddddddddddddddddd ${widget.userId}');
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications')),
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear All',
              onPressed: _clearAllNotifications,
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final date = notification['createdAt'] != null
                    ? DateTime.parse(
                        notification['createdAt'],
                      ).toLocal().toString().substring(0, 16)
                    : '';

                return Dismissible(
                  key: Key(notification['_id'].toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    _deleteNotification(notification['_id'].toString(), index);
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(
                        Icons.notifications,
                        color: Colors.blue,
                      ),
                    ),
                    title: Text(
                      notification['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(notification['message'] ?? ''),
                        const SizedBox(height: 4),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
