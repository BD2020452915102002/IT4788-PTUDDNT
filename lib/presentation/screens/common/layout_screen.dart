import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/presentation/screens/common/chat.dart';
import 'package:ptuddnt/presentation/screens/common/home_screen.dart';
import 'package:ptuddnt/presentation/screens/common/notifycation_screen.dart';
import 'package:ptuddnt/presentation/screens/student/class/list_assignment.dart';

class LayoutScreen extends StatelessWidget {
  const LayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: Navigation(),
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
    _initializeData();
  }

  Future<void> _initializeData() async {
    final countNotify = HiveService().getData('thongbao');
    if (countNotify == null) {
      await fetchUnreadNotificationsCount();
    }
    setState(() {
      unreadNotificationsCount = HiveService().getData('thongbao');
    });

  }

  Future<void> fetchUnreadNotificationsCount() async {
    try {
      final token = Token().get();
      final response = await ApiClass()
          .post('/get_unread_notification_count', {"token": token});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await HiveService().saveData('thongbao', data['data']);
      } else {
        print('Không thể tải số thông báo chưa đọc');
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
        await HiveService().saveData('thongbao', data['data']);
        setState(() {
          unreadNotificationsCount = HiveService().getData('thongbao');
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
    Theme.of(context);
    final role = HiveService().getData('userData')['role'];
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        indicatorColor: AppColors.primary,
        selectedIndex: currentPageIndex,
        destinations: role == 'STUDENT'
            ? <Widget>[
                NavigationDestination(
                  selectedIcon: Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                  icon: Icon(Icons.home_outlined),
                  label: 'Trang chủ',
                ),
                NavigationDestination(
                  selectedIcon: Icon(
                    Icons.assignment,
                    color: Colors.white,
                  ),
                  icon: Icon(Icons.assignment_outlined),
                  label: 'Bài tập',
                ),
                // NavigationDestination(
                //   icon: Badge(
                //     label: Text('1'),
                //     child: const Icon(Icons.messenger_outline_sharp),
                //   ),
                //   selectedIcon: Badge(
                //     label: Text('1'),
                //     child: const Icon(
                //       Icons.messenger_sharp,
                //       color: Colors.white,
                //     ),
                //   ),
                //   label: 'Tin nhắn',
                // ),
                NavigationDestination(
                  icon: unreadNotificationsCount == 0
                      ? Icon(Icons.notifications_none)
                      : Badge(
                          label: Text('$unreadNotificationsCount'),
                          child: const Icon(Icons.notifications_none),
                        ),
                  selectedIcon: unreadNotificationsCount == 0
                      ? Icon(
                          Icons.notifications_sharp,
                          color: Colors.white,
                        )
                      : Badge(
                          label: Text('$unreadNotificationsCount'),
                          child: const Icon(
                            Icons.notifications_sharp,
                            color: Colors.white,
                          ),
                        ),
                  label: 'Thông báo',
                ),
              ]
            : <Widget>[
                NavigationDestination(
                  selectedIcon: Icon(
                    Icons.home,
                    color: Colors.white,
                  ),
                  icon: Icon(Icons.home_outlined),
                  label: 'Trang chủ',
                ),
                // NavigationDestination(
                //   icon: Badge(
                //     label: Text('1'),
                //     child: const Icon(Icons.messenger_outline_sharp),
                //   ),
                //   selectedIcon: Badge(
                //     label: Text('1'),
                //     child: const Icon(
                //       Icons.messenger_sharp,
                //       color: Colors.white,
                //     ),
                //   ),
                //   label: 'Tin nhắn',
                // ),
                NavigationDestination(
                  icon: unreadNotificationsCount == 0
                      ? Icon(Icons.notifications_none)
                      : Badge(
                          label: Text('$unreadNotificationsCount'),
                          child: const Icon(Icons.notifications_none),
                        ),
                  selectedIcon: unreadNotificationsCount == 0
                      ? Icon(
                          Icons.notifications_sharp,
                          color: Colors.white,
                        )
                      : Badge(
                          label: Text('$unreadNotificationsCount'),
                          child: const Icon(
                            Icons.notifications_sharp,
                            color: Colors.white,
                          ),
                        ),
                  label: 'Thông báo',
                ),
              ],
      ),
      body: role == 'STUDENT'
          ? <Widget>[
              HomeScreen(),
              ListAssignment(),
              // ChatScreen(),
              NotifycationScreen(fetchUnreadNotificationsCount: setCount)
            ][currentPageIndex]
          : <Widget>[
              HomeScreen(),
              // ChatScreen(),
              NotifycationScreen(fetchUnreadNotificationsCount: setCount)
            ][currentPageIndex],
    );
  }
}
