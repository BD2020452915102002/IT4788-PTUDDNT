// import 'dart:convert';
// import 'package:http/http.dart' as http;
//
// class NotificationService {
//   final String apiUrl = "https://example.com/send_notification"; // Thay bằng URL API của bạn
//
//   Future<void> sendNotificationToOne({
//     required String message,
//     required int toUser,
//     required String type,
//   }) async {
//     final response = await _sendNotification(
//       token: token,
//       message: message,
//       toUser: toUser,
//       type: type,
//     );
//
//     if (response.statusCode == 200) {
//       print("Notification sent successfully to user $toUser");
//     } else {
//       print("Failed to send notification: ${response.body}");
//     }
//   }
//
//   // Phương thức gửi thông báo tới nhiều người
//   Future<void> sendNotificationToMultiple({
//     required String token,
//     required String message,
//     required List<int> toUsers,
//     required String type,
//   }) async {
//     for (var toUser in toUsers) {
//       await sendNotificationToOne(
//         token: token,
//         message: message,
//         toUser: toUser,
//         type: type,
//       );
//     }
//   }
//
//
//   Future<http.Response> _sendNotification({
//     required String token,
//     required String message,
//     required int toUser,
//     required String type,
//   }) {
//     final headers = {"Content-Type": "application/json"};
//     final body = json.encode({
//       "token": token,
//       "message": message,
//       "to_user": toUser,
//       "type": type,
//     });
//
//     return http.post(
//       Uri.parse(apiUrl),
//       headers: headers,
//       body: body,
//     );
//   }
// }
