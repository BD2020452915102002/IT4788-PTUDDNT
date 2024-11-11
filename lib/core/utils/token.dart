import 'package:shared_preferences/shared_preferences.dart';

class Token {
  Future<String?> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> save(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<void> remove() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
