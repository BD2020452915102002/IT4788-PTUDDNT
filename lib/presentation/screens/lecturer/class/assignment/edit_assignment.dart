import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../../../core/constants/colors.dart';

class EditAssignmentScreen extends StatefulWidget {
  final String token;
  final int assignmentId;
  final String title;
  final String description;
  final DateTime deadline;

  const EditAssignmentScreen({
    Key? key,
    required this.token,
    required this.assignmentId,
    required this.title,
    required this.description,
    required this.deadline,
  }) : super(key: key);

  @override
  _EditAssignmnetScreenState createState() => _EditAssignmnetScreenState();
}
class _EditAssignmnetScreenState extends State<EditAssignmentScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController deadlineController = TextEditingController();
  File? selectedFile;

  @override
  void initState() {
    super.initState();
    titleController.text = widget.title;
    descriptionController.text = widget.description;
    deadlineController.text = DateFormat('HH:mm dd/MM/yyyy').format(widget.deadline); // Định dạng deadline
  }

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }
  Future<void> saveChanges() async {
    String formattedDeadline;
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn file trước khi lưu')),
      );
      return;
    }
    print('Title trước khi gọi API: ${titleController.text}');
    print('Description: ${descriptionController.text}');
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://157.66.24.126:8080/it5023e/edit_survey?file'),
    );
    if (deadlineController.text.contains('T')) {
      DateTime parsedDeadline = DateFormat('yyyy-MM-ddTHH:mm:ss').parse(deadlineController.text);
      formattedDeadline = DateFormat('yyyy-MM-ddTHH:mm:ss').format(parsedDeadline);
    } else {
      DateTime parsedDeadline = DateFormat('HH:mm dd/MM/yyyy').parse(deadlineController.text);
      formattedDeadline = DateFormat('yyyy-MM-ddTHH:mm:ss').format(parsedDeadline);
    }
    request.fields['assignmentId'] = widget.assignmentId.toString();
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['deadline'] =  formattedDeadline;
    request.fields['token'] = widget.token;
    request.files.add(
      await http.MultipartFile.fromPath('file', selectedFile!.path),
    );
    print('deadline: ${formattedDeadline}');

    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu thành công')),
      );
      final responseBody = await response.stream.bytesToString();
      print('Nội dung phản hồi: $responseBody');
      Navigator.pop(context, true);
    } else {
      print('Lưu thất bại: ${response.statusCode}');
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
          "Sửa bài tập",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Căn trái các label
          children: [
            // Tiêu đề Title
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

            // Tiêu đề Description
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
            const SizedBox(height: 16),

            // Tiêu đề Deadline
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
            const SizedBox(height: 32), // Tạo khoảng cách trước nút

            // Các nút bấm được căn giữa
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
                    onPressed: selectFile,
                    child: Text(
                      selectedFile == null
                          ? 'Choose File'
                          : 'File: ${selectedFile!.path.split('/').last}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC02135),
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    onPressed: saveChanges,
                    child: Text(
                      'Save',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
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