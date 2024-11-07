import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/api_authen.dart';
import '../../core/constants/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await ApiService().post('/login', {
      'email': _emailController.text,
      'password': _passwordController.text,
      'deviceId': 1
    });

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Lưu thông tin người dùng vào SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userData', jsonEncode(data));
      if (!mounted) return;
      String? role = jsonDecode(prefs.getString('userData')!)['role'];
      // Điều hướng tới trang Home nếu đăng nhập thành công
      if (role == 'STUDENT') {
        Navigator.pushReplacementNamed(context, '/home-student');
      } else if (role == 'LECTURER') {
        Navigator.pushReplacementNamed(context, '/home-lecturer');
      }
    } else {
      setState(() {
        _errorMessage = 'Đăng nhập thất bại. Vui lòng thử lại.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Row(
                children: [
                  Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'HUST',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'APP',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'One love, one future',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            color: AppColors.textColorBlur,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 80),
                    child: Image(
                      image: AssetImage("assets/logo-hust.png"),
                      height: 180,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 40),
              Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email), // Thêm biểu tượng email ở bên trái
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0), // Bo tròn khung
                        borderSide: const BorderSide(
                          color:Colors.white70, // Màu của đường viền
                          width: 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: const BorderSide(
                          color: Colors.grey, // Màu đường viền khi được chọn
                          width: 1.0,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 15.0), // Đệm trong của TextField
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu',
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text('Đăng nhập'),
                        ),
                  const SizedBox(height: 16),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context,
                              '/register'); // Điều hướng tới màn hình đăng ký
                        },

                        child: const Text('Đăng ký'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context,
                              '/forgot_password'); // Điều hướng tới màn hình quên mật khẩu
                        },
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ],
                  )
                ],
              ),
            ],
          )),
    );
  }
}
