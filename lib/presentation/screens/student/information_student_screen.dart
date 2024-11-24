import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class StudentInfoScreen extends StatefulWidget {
  final String userId;
  const StudentInfoScreen({super.key, required this.userId});
  @override
  StudentInfoScreenState createState() => StudentInfoScreenState();
}

class StudentInfoScreenState extends State<StudentInfoScreen> {
  Map<String, dynamic> userData = {};
  late String token = '';
  late String hoTen = '';
  String? _imagePath;
  bool isLoading = false;
  bool isPasswordLoading = false;
  bool isButtonEnabled = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    token = Token().get();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final url = Uri.parse('http://157.66.24.126:8080/it4788/get_user_info');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'userId': widget.userId}),
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = jsonDecode(response.body)['data'];
        hoTen = '${userData['ho']} ${userData['ten']}';
      });
    } else {
      print('Failed to load user data');
    }
  }

  Future<void> _changePassword() async {
    setState(() {
      isPasswordLoading = true;
    });
    final url = Uri.parse('http://157.66.24.126:8080/it4788/change_password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'old_password': _oldPasswordController.text,
        'new_password': _newPasswordController.text,
      }),
    );

    setState(() {
      isPasswordLoading = false;
    });

    if (response.statusCode == 200) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đổi mật khẩu thất bại')),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _updateAvatar() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse('http://157.66.24.126:8080/it4788/change_info_after_signup');
    final request = http.MultipartRequest('POST', url);
    request.fields['token'] = token;
    if (_imagePath != null) {
      final file = File(_imagePath!);
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();
    final data = jsonDecode(responseData);

    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        hoTen = '${data['data']['name']}';
        userData['avatar'] = data['data']['avatar'];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thất bại')),
      );
    }
  }

  String convertToDirectDownloadLink(String driveLink) {
    final regex = RegExp(r'file/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(driveLink);

    if (match != null && match.groupCount > 0) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    } else {
      throw ArgumentError('Invalid Google Drive link format');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.tertiary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Thông tin sinh viên",
          style: TextStyle(
            color: AppColors.tertiary,
            fontStyle: FontStyle.normal,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Image(
                image: AssetImage("assets/anhbia-hust.png"),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 20,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: userData['avatar'] != null
                                ? NetworkImage(convertToDirectDownloadLink(userData['avatar']))
                                : null,
                            child: userData['avatar'] == null
                                ? const Icon(Icons.person, size: 30)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () async {
                                await _pickImage();
                                if (_imagePath != null) {
                                  _updateAvatar();
                                }
                              },
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: AppColors.primary50,
                                child: const Icon(Icons.camera_alt, size: 15, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hoTen,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Email: ${userData['email'] ?? 'Không có'}',
                            style: const TextStyle(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color(0xD3FBF8EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Họ tên: $hoTen',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Id sinh viên: ${userData['id'] ?? 'Không có'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Email: ${userData['email'] ?? 'Không có'}',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      _oldPasswordController.clear();
                      _newPasswordController.clear();
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (dialogContext) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  height: MediaQuery.of(context).size.height * 0.4,
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text(
                                          "Đổi mật khẩu",
                                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 20),
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Mật khẩu cũ",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _oldPasswordController,
                                          obscureText: true,
                                          onChanged: (value) {
                                            setState(() {
                                              isButtonEnabled = value.length >= 6 &&
                                                  _newPasswordController.text.length >= 6;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: AppColors.primary,
                                                width: 2.0,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Mật khẩu mới
                                        const Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            "Mật khẩu mới",
                                            style: TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextField(
                                          controller: _newPasswordController,
                                          obscureText: true,
                                          onChanged: (value) {
                                            setState(() {
                                              isButtonEnabled = value.length >= 6 &&
                                                  _oldPasswordController.text.length >= 6;
                                            });
                                          },
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(18),
                                              borderSide: BorderSide(
                                                color: AppColors.primary,
                                                width: 2.0,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        // Nút xác nhận
                                        ElevatedButton(
                                          onPressed: isButtonEnabled
                                              ? () async {
                                            if (_oldPasswordController.text.isNotEmpty && _newPasswordController.text.isNotEmpty) {
                                              await _changePassword();
                                            }
                                          }
                                              : null,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            minimumSize: const Size(160, 48),
                                          ),
                                          child: isPasswordLoading
                                              ? const CircularProgressIndicator(color: Colors.white)
                                              : const Text("Xác nhận"),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Thay đổi mật khẩu',
                      style: TextStyle(
                        color: Colors.orange,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (isLoading) const CircularProgressIndicator(),
        ],
      ),
    );
  }
}
