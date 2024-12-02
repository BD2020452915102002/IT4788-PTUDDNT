import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/presentation/themes/app_theme.dart';
import 'package:ptuddnt/routes/app_routes.dart';
import 'package:ptuddnt/core/utils/notification.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Hive.initFlutter();
  await HiveService().initBox('HustBox');

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        print("Initial message received: ${message.messageId}");
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("Message received: ${message.messageId}");
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Message opened app: ${message.messageId}");
    });
  }

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