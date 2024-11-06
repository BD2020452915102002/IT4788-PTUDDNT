import 'package:flutter/material.dart';
import 'package:ptuddnt/presentation/screens/forgot_password_screen.dart';
import 'package:ptuddnt/presentation/screens/home_screenstudent.dart';
import 'package:ptuddnt/presentation/screens/splash_screen.dart';
import 'package:ptuddnt/presentation/screens/login_screen.dart';
import 'package:ptuddnt/presentation/screens/register_screen.dart';
import '../presentation/screens/home_screenlecture.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/home': (context) => const HomeScreen(),
    '/homeLec': (context) => const HomeScreenLec(),

    '/register': (context) => const RegisterScreen(),
    '/forgot_password': (context) => const ForgotPasswordScreen(),
  };
}
