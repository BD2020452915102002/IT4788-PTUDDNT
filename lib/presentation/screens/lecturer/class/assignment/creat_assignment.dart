import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../core/constants/colors.dart';

class CreateSurveyScreen extends StatefulWidget {
  final String token;
  final dynamic classId;
  const CreateSurveyScreen({Key? key, required this.token, required this.classId}) : super(key: key);
  @override
  _CreateSurveyScreenState createState() => _CreateSurveyScreenState();
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
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');

    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
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
      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse("http://160.30.168.228:8080/it5023e/create_survey"),
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
      Navigator.pop(context, true);
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
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              readOnly: true,
              onTap: () => _selectDateTime(context),
              decoration: InputDecoration(labelText: 'Deadline (YYYY-MM-DDTHH:MM:SS)'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
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
            SizedBox(height: 20),
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
    );
  }
}
