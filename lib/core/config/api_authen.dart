import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/config/api_config.dart';

class ApiAuthen {
  static const String baseUrl = ApiConfig.apiAuthen;
  static final ApiAuthen _instance = ApiAuthen._internal();
  factory ApiAuthen() {
    return _instance;
  }

  ApiAuthen._internal();

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl$endpoint');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );

    return response;
  }
}
