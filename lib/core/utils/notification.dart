import 'package:flutter/material.dart';

import '../constants/colors.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final GlobalKey<ScaffoldMessengerState> messengerKey = GlobalKey<ScaffoldMessengerState>();

  // Phương thức hiển thị SnackBar với khả năng tùy chỉnh style
  void showSnackBar(String message, {Color backgroundColor = Colors.blue, TextStyle? textStyle}) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: textStyle ?? const TextStyle(color: Colors.white),
      ),
      backgroundColor: backgroundColor,
      duration: const Duration(seconds: 2),
    );
    messengerKey.currentState?.showSnackBar(snackBar);
  }

  // Phương thức hiển thị AlertDialog với khả năng tùy chỉnh title và style
  void showAlertDialog(
      BuildContext context,
      String title,
      String message, {
        TextStyle? titleTextStyle,
        TextStyle? messageTextStyle,
        Color titleColor = AppColors.textColor,
        Color backgroundColor = Colors.white,
        Color buttonTextColor = AppColors.primary,
        String buttonText = "OK",
      }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            title,
            style: titleTextStyle ??
                TextStyle(
                  color: titleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          content: Text(
            message,
            style: messageTextStyle ?? const TextStyle(color: Colors.black),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                buttonText,
                style: TextStyle(color: buttonTextColor),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
