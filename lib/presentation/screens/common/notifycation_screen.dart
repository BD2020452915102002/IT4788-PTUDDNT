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
  int count =2;
  int index =0;

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
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiClass().post('/get_notifications', {
        "token": token,
        "index": index,
        "count": count
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
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
  Future<void> fetchNotificationsXXX() async {
    setState(() {
      isLoading = true;
    });
    print('day vao$index $count');
    try {
      final response = await ApiClass().post('/get_notifications', {
        "token": token,
        "index": index,
        "count": count
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        await HiveService().addToList('danhsachthongbao', data['data']);
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
  Future<void> markAllAsRead() async {
    final notificationIds = notifications.map((notification) => notification['id'].toString()).toList();
    await markAsRead(notificationIds);
  }
  Future<void> markSingleAsRead(String notificationId) async {
    await markAsRead([notificationId]);
  }
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
  Future<void> onRefresh ()async{
   await HiveService().deleteData('danhsachthongbao');
    setState(() {
      index = 0;
      count = 4;
    });
    await fetchNotifications();
    print('duc ${HiveService().getData('danhsachthongbao')}');
    setState(() {
      notifications = HiveService().getData('danhsachthongbao');
      isLoading = false;
    });
  }
  Future<void> onLoad ()async{
    await HiveService().deleteData('danhsachthongbao');
    setState(() {
      index = index + 2;
      count= count + 2;
    });
    await fetchNotificationsXXX();
    setState(() {
      notifications = HiveService().getData('danhsachthongbao');
      isLoading = false;

    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: AppColors.primary ,
      ),
      body: EasyRefresh(
        onLoad: onLoad ,
          onRefresh: onRefresh ,
          child: isLoading
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
                await markSingleAsRead(notification['id'].toString());
              },
            ),
          );
        },
      ))
    );
  }
}
