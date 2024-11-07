import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? userData = prefs.getString('userData');

    Timer(const Duration(seconds: 1), () {
      // Kiểm tra widget có còn tồn tại hay không
      if (!mounted) return;
      // prefs.remove('userData');
      if (userData != null) {
        final role = jsonDecode(userData)['role'];
        if(role == 'STUDENT'){
          Navigator.pushReplacementNamed(context, '/home-student');
        } else if(role == 'LECTURER'){
          Navigator.pushReplacementNamed(context, '/home-lecturer');
        }
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image(
              image: AssetImage("assets/logo-hust.png"),
              height: 200,
            ),
            SizedBox(height: 20),
            Text(
              'One love, one future',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
