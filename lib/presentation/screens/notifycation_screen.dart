import 'package:flutter/material.dart';
import 'dart:convert'; 
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/utils/token.dart';

class NotifycationScreen extends StatefulWidget {
  final Future<void> Function() fetchUnreadNotificationsCount;

  const NotifycationScreen({super.key, required this.fetchUnreadNotificationsCount});

  @override
  State<NotifycationScreen> createState() => _NotifycationScreenState();
}

class _NotifycationScreenState extends State<NotifycationScreen> {
  List<dynamic> notifications = [];
  bool isLoading = true;
  final String token = Token().get();

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await ApiClass().post('/get_notifications', {
        "token": token,
        "index": 0,
        "count": 100
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          notifications = data['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  // Hàm đánh dấu tất cả thông báo là đã đọc
  Future<void> markAllAsRead() async {
    final notificationIds = notifications.map((notification) => notification['id'].toString()).toList();
    await markAsRead(notificationIds);
  }

  // Hàm đánh dấu một thông báo là đã đọc
  Future<void> markSingleAsRead(String notificationId) async {
    await markAsRead([notificationId]);
  }

  // Hàm gọi API `/mark_notification_as_read`
  Future<void> markAsRead(List<String> notificationIds) async {
    try {
      final response = await ApiClass().post('/mark_notification_as_read', {
        "token": token,
        "notification_ids": notificationIds,
      });

      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications.map((notification) {
            if (notificationIds.contains(notification['id'].toString())) {
              notification['status'] = 'READ';
            }
            return notification;
          }).toList();
        });
        widget.fetchUnreadNotificationsCount(); // Gọi hàm truyền vào để cập nhật số thông báo
      } else {
        throw Exception('Failed to mark notifications as read');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () async {
              await markAllAsRead();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(notification['message']),
            subtitle: Text(notification['sent_time']),
            trailing: Text(
              notification['status'],
              style: TextStyle(
                color: notification['status'] == 'UNREAD' ? Colors.red : Colors.green,
              ),
            ),
            onTap: () async {
              // Đánh dấu một thông báo là đã đọc
              await markSingleAsRead(notification['id'].toString());
            },
          );
        },
      ),
    );
  }
}
