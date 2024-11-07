import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/config/api_config.dart';

class ApiService {
  static const String baseUrl = ApiConfig.apiAuthen;
  static final ApiService _instance = ApiService._internal();
  factory ApiService() {
    return _instance;
  }

  ApiService._internal();

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
