import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateSurveyScreen extends StatefulWidget {
  final String token;
  final int classId;
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
  String formatClassId(int classId) {
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
      print('Class ID from: $classId');
    } else {
      print("No user data found in SharedPreferences");
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create Survey")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: deadlineController,
              decoration: InputDecoration(labelText: 'Deadline (YYYY-MM-DDTHH:MM:SS)'),
            ),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: pickFile,
              child: Text(selectedFile != null ? "File Selected" : "Pick File"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: createSurvey,
              child: Text("Create Survey"),
            ),
          ],
        ),
      ),
    );
  }
}
