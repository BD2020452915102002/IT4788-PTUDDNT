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
  File? selectedImage;
  String _imageInfo = 'Upload Avatar';

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
        userName = '${userData['ho']} ${userData['ten']}';
      });
    } else {
      print('Failed to load user data');
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        _imageInfo = pickedFile.name;
      });
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
              fontFamily: "Roboto"
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Image.network(
                'https://bcp.cdnchinhphu.vn/334894974524682240/2022/12/5/dhbkhn-6920-1658994052-1-16702134834751920701721.jpg',
                width: double.infinity,
                height: 120,
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
                        backgroundImage: NetworkImage(
                          userData['avatar'] ?? 'https://th.bing.com/th/id/OIP.NigFEo-pLcgvitlruySZzQHaHa?rs=1&pid=ImgDetMain',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
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
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xFFFBF8EF),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20),
              //padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Họ tên: ${userName}',
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.35,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      'Chỉnh sửa thông tin',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image),
                      label: Text(_imageInfo),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(150, 50),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        // Lưu thông tin thay đổi
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 50),
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text('Lưu'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}
