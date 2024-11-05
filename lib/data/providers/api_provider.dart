// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// import '../models/user.dart';
// import '../../core/config/app_config.dart';
//
// class ApiProvider {
//   Future<List<User>> fetchUsers() async {
//     final response = await http.get(Uri.parse('${AppConfig.apiUrl}/users'));
//
//     if (response.statusCode == 200) {
//       List data = json.decode(response.body);
//       return data.map((json) => User.fromJson(json)).toList();
//     } else {
//       throw Exception('Failed to load users');
//     }
//   }
// }
