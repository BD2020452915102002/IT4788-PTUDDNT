import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/presentation/screens/chat.dart';
import 'package:ptuddnt/presentation/screens/lecturer/home_screen_lecture.dart';
import 'package:ptuddnt/presentation/screens/notifycation_screen.dart';

class HomeLectuter extends StatelessWidget {
  const HomeLectuter({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const Navigation(),
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
  int unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    fetchUnreadNotificationsCount();
  }

  Future<void> fetchUnreadNotificationsCount() async {
    final countNotify = HiveService().getData('thongbao');
    print('duc$countNotify');
    if (countNotify == null) {
      try {
        final response = await ApiClass()
            .post('/get_unread_notification_count', {"token": Token().get()});
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          HiveService().saveData('thongbao', data['data']);
        } else {
          throw Exception('Không thể tải số thông báo chưa đọc');
        }
      } catch (e) {
        print('Lỗi khi gọi API: $e');
      }
    }
    setState(() {
      unreadNotificationsCount = HiveService().getData('thongbao');
    });
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
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: Icon(
              Icons.home,
              color: Colors.white,
            ),
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('2'),
              child: Icon(Icons.messenger_sharp),
            ),
            label: 'Tin nhắn',
          ),
          NavigationDestination(
            icon: Badge(
              // label: Text(unreadNotificationsCount.toString()),
              child: Icon(Icons.notifications_sharp),
            ),
            selectedIcon: Badge(
              // label: Text(unreadNotificationsCount.toString()),
              child: Icon(
                Icons.notifications_sharp,
                color: Colors.white,
              ),
            ),
            label: 'Thông báo',
          ),
        ],
      ),
      body: <Widget>[
        HomeScreenLec(),
        ChatScreen(),
        NotifycationScreen(fetchUnreadNotificationsCount: fetchUnreadNotificationsCount)
      ][currentPageIndex],
    );
  }
}
