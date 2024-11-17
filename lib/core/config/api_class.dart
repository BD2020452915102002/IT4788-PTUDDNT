import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/config/api_config.dart';

class ApiClass {
  static const String baseUrl = ApiConfig.apiClass;
  static final ApiClass _instance = ApiClass._internal();

  factory ApiClass() {
    return _instance;
  }

  ApiClass._internal();

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

  Future<http.Response> get(String endpoint,
      {Map<String, String>? queryParameters}) async {
    final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParameters);
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
    };
    final response = await http.get(
      uri,
      headers: headers,
    );
    return response;
  }
}