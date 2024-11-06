import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/utils/helper.dart';

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
