import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/utils/hive.dart';
import '../../../../../core/constants/colors.dart';

class CreateSurveyScreen extends StatefulWidget {
  final String token;
  final dynamic classId;
  const CreateSurveyScreen({super.key, required this.token, required this.classId});
  @override
  State<CreateSurveyScreen> createState() => _CreateSurveyScreenState();
}

class _CreateSurveyScreenState extends State<CreateSurveyScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController deadlineController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  String? token;
  String? classId;
  File? selectedFile;
  String? selectedFileName;
  DateTime? selectedDeadline;
  String formatClassId(String classId) {
    return classId.toString().padLeft(6, '0'); // Ensure classId has at least 6 characters
  }
  @override
  void initState() {
    super.initState();
    classId = formatClassId(widget.classId);
    loadUserData();
  }

  Future<void> loadUserData() async {
    final userData = HiveService().getData('userData');
    if (userData != null) {
      setState(() {
        token = userData['token'];

      });

      print('Token from SharedPreferences: $token');
      print('Class ID from: ${classId.runtimeType}');
    } else {
      print("No user data found in SharedPreferences");
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        selectedFileName = result.files.single.name;
        print("File selected: ${selectedFile!.path}");
      });
    }
  }

  Future<void> createSurvey() async {
    if (selectedFile == null || token == null || classId == null) {
      print('token: $token');
      print('classId: $classId');
      print('selectedFile: $selectedFile');
      print("Token, classId, or file is missing");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing somethings...')),
      );
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://157.66.24.126:8080/it5023e/create_survey"),
    );

    request.fields['token'] = token!;
    request.fields['classId'] = classId!;
    request.fields['title'] = titleController.text;
    request.fields['deadline'] = deadlineController.text;
    request.fields['description'] = descriptionController.text;
    request.files.add(
      await http.MultipartFile.fromPath(
        'file',
        selectedFile!.path,
      ),
    );
    var response = await request.send();

    if (response.statusCode == 200) {
      print("Survey created successfully");
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tạo Bài tập thành công!')),
        );
      });
      Navigator.pop(context, true);
      // Navigator.pop(context, true);
    } else {
      print("Failed to create survey");
      final responseString = await response.stream.bytesToString();
      print("Response body: $responseString");
    }
  }
  Future<void> _selectDateTime(BuildContext context) async {
    // Chọn ngày
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      // Chọn giờ
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final DateTime fullDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Định dạng ngày giờ thành `YYYY-MM-DDTHH:MM:SS`
        final String formattedDateTime =
            "${fullDateTime.toIso8601String().split('.')[0]}";

        // Cập nhật trường Deadline
        setState(() {
          deadlineController.text = formattedDateTime;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_sharp,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: Text(
          "Tạo bài tập",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Giảm bo góc
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Deadline:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),

            ),
            TextField(
              controller: deadlineController,
              readOnly: true,
              onTap: () => _selectDateTime(context),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Giảm bo góc
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Description:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextField(
              controller: descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), // Giảm bo góc
                ),
              ),
            ),
            const SizedBox(height: 32), // Tạo khoảng cách trước nút bấm
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC02135),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    onPressed: pickFile,
                    child: Text(selectedFile != null ? "File Selected" : "Pick File"),
                  ),
                  if (selectedFileName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'File đã chọn: $selectedFileName',
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),
                  const SizedBox(height: 20), // Tạo khoảng cách giữa các nút
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC02135),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    onPressed: createSurvey,
                    child: Text("Create Survey"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
