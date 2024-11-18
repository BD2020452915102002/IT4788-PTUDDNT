import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/presentation/screens/chat.dart';
import 'package:ptuddnt/presentation/screens/lecturer/home_screen_lecture.dart';
import 'package:ptuddnt/presentation/screens/notifycation_screen.dart';
import 'package:ptuddnt/presentation/screens/student/class/list_assignment.dart';
import 'package:ptuddnt/presentation/screens/student/home_screen_student.dart';

class HomeStudent extends StatelessWidget {
  const HomeStudent({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home:  Navigation(),
    );
  }
}

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int currentPageIndex = 0;
  String unreadNotificationsCount = '';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final countNotify = HiveService().getData('thongbao');
    if (countNotify == null) {
      await fetchUnreadNotificationsCount();
    }
    setState(() {
      unreadNotificationsCount = HiveService().getData('thongbao').toString();
    });
  }

  Future<void> fetchUnreadNotificationsCount() async {
    try {
      final response = await ApiClass()
          .post('/get_unread_notification_count', {"token": Token().get()});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final unreadCount = data['data'];
        HiveService().saveData('thongbao', unreadCount);
      } else {
        throw Exception('Không thể tải số thông báo chưa đọc');
      }
    } catch (e) {
      print('Lỗi khi gọi API: $e');
    }
  }

  Future<void> setCount() async {
    try {
      final response = await ApiClass()
          .post('/get_unread_notification_count', {"token": Token().get()});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final unreadCount = data['data'];
        await HiveService().saveData('thongbao', unreadCount);
        setState(() {
          unreadNotificationsCount =
              HiveService().getData('thongbao').toString();
        });
      } else {
        throw Exception('Không thể tải số thông báo chưa đọc');
      }
    } catch (e) {
      print('Lỗi khi gọi API: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: AppColors.primary,
        selectedIndex: currentPageIndex,
        destinations: <Widget>[
          const NavigationDestination(
            selectedIcon: Icon(
              Icons.home,
              color: Colors.white,
            ),
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          const NavigationDestination(
            selectedIcon: Icon(
              Icons.assignment,
              color: Colors.white,
            ),
            icon: Icon(Icons.assignment_outlined),
            label: 'Bài tập',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('1'),
              child: const Icon(Icons.messenger_outline_sharp),
            ),
            selectedIcon: Badge(
              label: Text('1'),
              child: const Icon(
                Icons.messenger_sharp,
                color: Colors.white,
              ),
            ),
            label: 'Tin nhắn',
          ),
          NavigationDestination(
            icon: int.parse(unreadNotificationsCount) == 0
                ? Icon(Icons.notifications_none)
                : Badge(
                    label: Text(unreadNotificationsCount),
                    child: const Icon(Icons.notifications_none),
                  ),
            selectedIcon: int.parse(unreadNotificationsCount) == 0
                ? Icon(
                    Icons.notifications_sharp,
                    color: Colors.white,
                  )
                : Badge(
                    label: Text(unreadNotificationsCount),
                    child: const Icon(
                      Icons.notifications_sharp,
                      color: Colors.white,
                    ),
                  ),
            label: 'Thông báo',
          ),
        ],
      ),
      body: <Widget>[
        const HomeScreenStudent(),
        ListAssignment(),
        const ChatScreen(),
        NotifycationScreen(fetchUnreadNotificationsCount: setCount)
      ][currentPageIndex],
    );
  }
}
