import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/presentation/themes/app_theme.dart';
import 'package:ptuddnt/routes/app_routes.dart';
import 'core/utils/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  await HiveService().initBox('HustBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hust App',
      theme: AppTheme.lightTheme,
      scaffoldMessengerKey: NotificationService().messengerKey,
      initialRoute: '/',
      routes: AppRoutes.routes,
    );
  }
}
