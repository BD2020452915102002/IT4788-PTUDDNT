import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/presentation/screens/Chat.dart';
import 'package:ptuddnt/presentation/screens/notifycation_screen.dart';
import 'package:ptuddnt/presentation/screens/student/class/list_assignment.dart';
import 'package:ptuddnt/presentation/screens/student/home_screen_student.dart';

class NavigationBarAppStudent extends StatelessWidget {
  const NavigationBarAppStudent({super.key});

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
            icon: Badge(child: Icon(Icons.notifications_sharp)),
            label: 'Thông báo',
          ),
        ],
      ),
      body: <Widget>[
        HomeScreenStudent(),
        ChatScreen(),
        NotifycationScreen()
      ][currentPageIndex],
    );
  }
}
