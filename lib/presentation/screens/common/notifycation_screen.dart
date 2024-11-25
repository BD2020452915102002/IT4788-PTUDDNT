import 'package:easy_refresh/easy_refresh.dart';
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
  bool isLoading = false;
  final String token = Token().get();
  int count = 5;
  int index = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      isLoading = true;
    });

    final countNotify = HiveService().getData('danhsachthongbao');
    if (countNotify == null) {
      await fetchNotifications(isInitial: true);
    } else {
      setState(() {
        notifications = countNotify;
        isLoading = false;
      });
    }
  }

  Future<void> fetchNotifications({bool isInitial = false}) async {
    try {
      if (isInitial) {
        setState(() {
          isLoading = true;
        });
      }

      final response = await ApiClass().post('/get_notifications', {
        "token": token,
        "index": index,
        "count": count
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));

        if (isInitial) {
          await HiveService().saveData('danhsachthongbao', data['data']);
        } else {
          await HiveService().addToList('danhsachthongbao', data['data']);
        }

        setState(() {
          notifications = HiveService().getData('danhsachthongbao');
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

  String format(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    return DateFormat('dd-MM-yyyy, HH:mm').format(deadlineDate);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final response = await ApiClass().post('/mark_notification_as_read', {
        "token": token,
        "notification_id": notificationId,
      });

      if (response.statusCode == 200) {
        setState(() {
          notifications = notifications.map((notification) {
            if (notification['id'].toString() == notificationId) {
              notification['status'] = 'READ';
            }
            return notification;
          }).toList();
        });
        widget.fetchUnreadNotificationsCount();
      } else {
        throw Exception('Failed to mark notifications as read');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> onRefresh() async {
    setState(() {
      isLoading = true;
      index = 0;
      count = 10;
    });
    await HiveService().deleteData('danhsachthongbao');
    await fetchNotifications(isInitial: true);
  }

  Future<void> onLoad() async {
    final list =  await HiveService().getData('danhsachthongbao');
    if ( list.length < (index + count)){

    }else {
      setState(() {
        isLoading = true;
        index += 5;
        count += 5;
      });
      await fetchNotifications(isInitial: false);
    }
  }

  void _showNotificationDetailDialog(BuildContext context, Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(notification['title_push_notification']),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification['message'],
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'Thời gian: ${formatDate(notification['sent_time'])}',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (notification['status'] == 'UNREAD') {
                    markAsRead(notification['id'].toString());
                  setState(() {
                    notification['status'] = 'READ';
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Đóng', style: TextStyle(color: Colors.red),),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white),),
        backgroundColor: AppColors.primary,
        centerTitle: true,
      ),
      body: EasyRefresh(
        onRefresh: fetchNotifications,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : notifications.isEmpty
            ? const Center(child: Text('Không có thông báo nào'))
            : ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(notification['message']),
              subtitle: Text(formatDate(notification['sent_time'])),
              trailing: Text(
                notification['status'],
                style: TextStyle(
                  color: notification['status'] == 'UNREAD' ? Colors.red : Colors.green,
                ),
              ),
              tileColor: notification['status'] == 'UNREAD'
                  ? Colors.orange[50]
                  : Colors.transparent,
              onTap: () => _showNotificationDetailDialog(context, notification),
            );
          },
        ),
      ),
    );
  }
}

String formatDate(String sentTime) {
  final dateTime = DateTime.parse(sentTime);
  return DateFormat('dd-MM-yyyy, HH:mm').format(dateTime);
}