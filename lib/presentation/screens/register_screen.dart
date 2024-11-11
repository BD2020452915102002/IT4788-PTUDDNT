import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import '../../core/config/api_authen.dart';
import '../../core/utils/notification.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _hoController = TextEditingController();
  final TextEditingController _tenController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String roleValue = 'STUDENT';
  bool _isLoading = false;
  String _errorMessage = '';

  static const List<Map<String, String>> roles = <Map<String, String>>[
    {'value': 'STUDENT', 'label': 'Học sinh'},
    {'value': 'LECTURER', 'label': 'Giảng viên'},
  ];

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      final response = await ApiAuthen().post('/signup', {
        "ho": _hoController.text,
        "ten": _tenController.text,
        "email": _emailController.text,
        "password": _passwordController.text,
        "role": roleValue
      });

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final verifyCode = responseData['verify_code'];
        final res = await ApiAuthen().post('/check_verify_code', {
          "email": _emailController.text,
          "verify_code": verifyCode
        });
        if (res.statusCode == 200) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(context, '/login');
          NotificationService().showAlertDialog(
              context, "Chúc mừng", "Bạn đã đăng ký thành công");
        } else {
          setState(() {
            _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Đăng ký thất bại. Vui lòng thử lại.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Đăng ký',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.normal,
          ),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  'Điền thông tin đăng ký',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _hoController,
                            decoration: const InputDecoration(
                              hintText: 'Họ',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Color(0xffd96060),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập họ';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: TextFormField(
                            controller: _tenController,
                            decoration: const InputDecoration(
                              hintText: 'Tên',
                              prefixIcon: Icon(
                                Icons.person,
                                color: Color(0xffd96060),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(
                          Icons.email,
                          color: Color(0xffd96060),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập email';
                        } else if (!RegExp(
                                r'^[a-zA-Z0-9._%+-]+@(hust\.edu\.vn|soict\.hust\.edu\.vn)$')
                            .hasMatch(value)) {
                          return 'Email không hợp lệ. Chỉ chấp nhận hust.edu.vn hoặc soict.hust.edu.vn';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        hintText: 'Mật khẩu',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Color(0xffd96060),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        } else if (value.length < 6) {
                          return 'Mật khẩu phải có ít nhất 6 ký tự';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: const InputDecoration(
                        hintText: 'Nhập lại mật khẩu',
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Color(0xffd96060),
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập lại mật khẩu';
                        } else if (value != _passwordController.text) {
                          return 'Mật khẩu không khớp';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: roles.map<Widget>((Map<String, String> role) {
                        return Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Radio<String>(
                                    value: role['value']!,
                                    groupValue: roleValue,
                                    onChanged: (String? value) {
                                      setState(() {
                                        roleValue = value!;
                                      });
                                    },
                                  ),
                                  Text(
                                    role['label']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _register,
                              child: const Text('Đăng ký'),
                            ),
                    ),
                    const SizedBox(height: 16),
                    if (_errorMessage.isNotEmpty)
                      Center(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}
