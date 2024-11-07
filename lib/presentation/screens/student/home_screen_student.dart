import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }
  Future<void> _logout() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('userData');

      if (!mounted) return;
      Navigator.pushNamed(context,
          '/login');

  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: Center(
        child: Column(
          children: [
            const Text('Đây là trang chủ sinh vien'),
            TextButton(
              onPressed: _logout,
              child: const Text('Đăng xuất'),
            ),
          ],

        ),
      ),
    );
  }
}
