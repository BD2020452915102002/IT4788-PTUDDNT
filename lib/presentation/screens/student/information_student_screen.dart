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
  late String userName = '';
  late String hoTen = '';
  String? _imageInfo;
  String? _imagePath;
  bool isLoading = false;
  bool isPasswordLoading = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _getToken();
  }

  Future<void> _getToken() async {
    token = (await Token().get())!;
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final url = Uri.parse('http://160.30.168.228:8080/it4788/get_user_info');
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
    final url = Uri.parse('http://160.30.168.228:8080/it4788/change_password');
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
        _imageInfo = pickedFile.name;
        _imagePath = pickedFile.path;
      });
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
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: userData['avatar'] != null
                            ? NetworkImage(convertToDirectDownloadLink(userData['avatar']))
                            : null,
                        child: userData['avatar'] == null
                            ? const Icon(Icons.person, size: 30)
                            : null,
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
                      showDialog(
                        context: context,
                        builder: (dialogContext) {
                          return StatefulBuilder(
                            builder: (context, setState) {
                              return Dialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.9,
                                  height: MediaQuery.of(context).size.height * 0.5,
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
                                        TextField(
                                          controller: _oldPasswordController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: "Mật khẩu cũ",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        TextField(
                                          controller: _newPasswordController,
                                          obscureText: true,
                                          decoration: const InputDecoration(
                                            labelText: "Mật khẩu mới",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        Center(
                                          child: ElevatedButton(
                                            onPressed: isPasswordLoading
                                              ? null
                                              : () async {
                                                setState(() {
                                                  isPasswordLoading = true;
                                                });
                                                await _changePassword();
                                                setState(() {
                                                  isPasswordLoading = false;
                                                });
                                              },
                                            style: ElevatedButton.styleFrom(
                                              minimumSize: const Size(100, 50),
                                            ),
                                            child: isPasswordLoading
                                              ? const CircularProgressIndicator()
                                              : const Text("Xác nhận"),
                                          ),
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
                      "Thay đổi mật khẩu",
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
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  //bool isLoading = false;
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Chỉnh sửa thông tin',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.all(Radius.circular(15)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              await _pickImage();
                              setState(() {});
                            },
                            icon: Icon(_imagePath == null ? Icons.image : Icons.check_circle),
                            label: Text(_imageInfo ?? 'Upload Avatar'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(150, 50),
                              backgroundColor: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 60),

                          SizedBox(
                            width: 120,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading
                                ? null
                                : () async {
                                  setState(() {
                                    isLoading = true;
                                    userName = _usernameController.text;
                                  });
                                  final url = Uri.parse('http://160.30.168.228:8080/it4788/change_info_after_signup');
                                  final request = http.MultipartRequest('POST', url);

                                  request.fields['token'] = token;
                                  request.fields['name'] = userName;
                                  if (_imagePath != null) {
                                    final file = File(_imagePath!);
                                    request.files.add(
                                      await http.MultipartFile.fromPath('file', file.path),
                                    );
                                  }

                                  final response = await request.send();
                                  final responseData = await response.stream.bytesToString();
                                  final data = jsonDecode(responseData);

                                  setState(() {
                                    isLoading = false;
                                  });

                                  if (response.statusCode == 200) {
                                    Navigator.pop(context);

                                    setState(() {
                                      hoTen = '${data['data']['ten']} ${data['data']['ten']}';
                                      userData['avatar'] = data['data']['avatar'];
                                    });

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cập nhật thông tin thành công')),
                                    );
                                  } else {
                                    Navigator.pop(context);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Cập nhật thông tin thất bại')),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(120, 50),
                                  backgroundColor: AppColors.primary,
                                ),
                              child: isLoading
                                  ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        strokeWidth: 2.0,
                                      ),
                                      const SizedBox(width: 10),
                                      const Text('Đang lưu...'),
                                    ],
                                  )
                                      : const Text('Lưu'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),

    );
  }
}