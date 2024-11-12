import 'package:flutter/material.dart';
import 'package:ptuddnt/presentation/screens/forgot_password_screen.dart';
import 'package:ptuddnt/presentation/screens/lecturer/class/detail_class_screen.dart';
import 'package:ptuddnt/presentation/screens/student/home_screen_student.dart';
import 'package:ptuddnt/presentation/screens/splash_screen.dart';
import 'package:ptuddnt/presentation/screens/login_screen.dart';
import 'package:ptuddnt/presentation/screens/register_screen.dart';
import '../presentation/screens/lecturer/home_screen_lecture.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/home-student': (context) => const HomeScreen(),
    '/home-lecturer': (context) => const HomeScreenLec(),

    '/class-detail': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return DetailClassScreen(classData: classData);
    },
    '/register': (context) => const RegisterScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),
  };
}
