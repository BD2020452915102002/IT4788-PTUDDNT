import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
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
    _initializeData();
  }
  Future<void> _initializeData() async {
    final countNotify = HiveService().getData('danhsachthongbao');
    if (countNotify == null) {
      await fetchNotifications();
    }
    setState(() {
      notifications = HiveService().getData('danhsachthongbao');
      isLoading = false;
    });
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
        await HiveService().saveData('danhsachthongbao', data['data']);
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
  String format(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    return DateFormat('dd-MM-yyyy, HH:mm').format(deadlineDate);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: AppColors.primary ,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read , color: Colors.white,),
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
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(notification['message']),
              subtitle: Text(format(notification['sent_time'])),
              trailing: Text(
                notification['status'],
                style: TextStyle(
                  color: notification['status'] == 'UNREAD' ? Colors.red : Colors.green,
                ),
              ),
              tileColor: notification['status'] == 'UNREAD' ? Colors.orange[50] : Colors.transparent,
              onTap: () async {
                // Đánh dấu một thông báo là đã đọc
                await markSingleAsRead(notification['id'].toString());
              },
            ),
          );
        },
      )
    );
  }
}
