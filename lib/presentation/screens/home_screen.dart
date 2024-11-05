import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import '../../data/models/user.dart';
import '../../data/repositories/user_repository.dart';
import '../../core/utils/helper.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
      ),
      body: const Center(
        child: Text('Đây là trang chủ'),
      ),
    );
  }
}
