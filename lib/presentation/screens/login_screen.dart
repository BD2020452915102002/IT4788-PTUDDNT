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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

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
        child: Form(
          key: _formKey, // Associate the form key with the Form widget
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
                    padding: EdgeInsets.only(left: 60),
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
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập email',
                      prefixIcon: Icon(
                        Icons.email,
                        color: Color(0xffd96060),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '          Vui lòng nhập email';
                      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value)) {
                        return '          Vui lòng nhập email lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: Icon(
                        Icons.key,
                        color: Color(0xffd96060),
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 15.0),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '          Vui lòng nhập mật khẩu';
                      } else if (value.length < 6) {
                        return '          Mật khẩu phải có ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _login,
                            child: const Text('Đăng nhập'),
                          ),
                  ),
                  const SizedBox(height: 16),
                  if (_errorMessage.isNotEmpty)
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/register');
                        },
                        child: const Text('Đăng ký'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgot_password');
                        },
                        child: const Text('Quên mật khẩu?'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
