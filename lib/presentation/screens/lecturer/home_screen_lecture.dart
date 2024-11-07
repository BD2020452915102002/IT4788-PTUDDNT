import 'package:flutter/material.dart';

class HomeScreenLec extends StatefulWidget {
  const HomeScreenLec({super.key});

  @override
  State<HomeScreenLec> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreenLec> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Đây là trang chủ giảng viên'),
      ),
    );
  }
}
