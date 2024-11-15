import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../data/models/assign.dart';
import 'creat_assignment.dart';

class AssignmentPage extends StatefulWidget {
  final String token;
  final dynamic classId;

  const AssignmentPage({Key? key, required this.token, required this.classId}) : super(key: key);

  @override
  State<AssignmentPage> createState() => __AssignmentPageState();
}

class __AssignmentPageState extends State<AssignmentPage> {

  List<Assignment> assign = [];
  bool isLoading = true;
  String token = '';
  List<Assignment> ongoingAssignments = [];
  List<Assignment> expiredAssignments = [];
  bool isReloading = false;
  late dynamic classId;
  String? selectedFileName;
  File? selectedFile;

  @override
  void initState() {
    super.initState();
    loadAssignments();
    reloadAssignments(widget.token,widget.classId);
  }

  Future<void> loadAssignments() async {
    assign = await fetchAssignments(widget.token, widget.classId as String);
    _splitAssignments();
    setState(() {
      isLoading = false;
    });
  }

  Future<List<Assignment>> fetchAssignments(String token, String classId) async {
    final response = await http.post(
      Uri.parse('http://160.30.168.228:8080/it5023e/get_all_surveys'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "token": widget.token,
        "class_id": classId.toString().padLeft(6, '0'),
      }),
    );
    print('Token: $token');
    print('Class ID: $classId');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((json) => Assignment.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load assignments');
    }
  }
  Future<void> loadUserDataAndFetchAssign() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');

    if (userDataString != null) {
      final userData = jsonDecode(userDataString);
      setState(() {
        token = userData['token'] ?? ''; // Gán token vào biến lớp
      });
      final classId = userData['class_id'] ?? '';


      try {
        final fetchedAssign = await fetchAssignments(token, classId);
        setState(() {
          assign = fetchedAssign;
          isLoading = false;
          print("Assign: $assign");
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        print("Error fetching assign list: $e");
      }
    } else {
      setState(() {
        isLoading = false;
      });
      print("No user data found in SharedPreferences");
    }
  }
  void _splitAssignments() {
    ongoingAssignments.clear();
    expiredAssignments.clear();
    final now = DateTime.now();

    for (var assignItem in assign) {
      if (assignItem.deadline != null && assignItem.deadline.isAfter(now)) {
        ongoingAssignments.add(assignItem); // Đang trong quá trình
      } else {
        expiredAssignments.add(assignItem); // Đã hết hạn
      }
    }
  }
  void navigateToCreateSurvey() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateSurveyScreen(token: widget.token,
        classId: widget.classId,)),
    );

    if (result == true) {
      reloadAssignments( widget.token, widget.classId,); // Tải lại dữ liệu assignments khi có assignment mới
    }
  }

// Hàm reloadAssignments trong AssignmentPage
  Future<void> reloadAssignments(String token, String classId) async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://160.30.168.228:8080/it5023e/get_all_surveys'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "token": token,
          "class_id": classId.toString().padLeft(6, '0'),
        }),
      );
      print('Token form relod: $token');
      print('Class ID form relod: $classId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          assign= data['assignments'];
          isLoading = false;
        });
      } else {
        print("Failed to load assignments");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        // Lưu đường dẫn file dưới dạng String
        selectedFile = File(result.files.single.path!);
        selectedFileName = result.files.single.name;
        print("File selected: $selectedFile");
      });
    } else {
      print("No file selected");
    }
  }
  @override
  Widget build(BuildContext context) {
    _splitAssignments();
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
          "Bài tập",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Stack(

        children: [
          isLoading
              ? Center(child: CircularProgressIndicator())
              : assign.isEmpty
              ? Center(child: Text("No Assign found."))
              : ListView(
            children: [
              const SizedBox(height: 16),
              //inProcessAssignments
              if (ongoingAssignments.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 16),
                  child: Text(
                    "Đang trong quá trình",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                for (var assignItem in ongoingAssignments)
                  _buildAssignmentCard(assignItem),
              ],
              //HetHanAssignments
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Text(
                  "Đã hết hạn",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (expiredAssignments.isNotEmpty)
                for (var assignItem in expiredAssignments)
                  _buildAssignmentCard(assignItem),
              if (ongoingAssignments.isEmpty && expiredAssignments.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Không có bài tập nào.'),
                ),
            ],
          ),
          // Nút FloatingActionButton nằm ở góc dưới bên phải
          Positioned(
            bottom: 50.0,
            right: 20.0,
            child: FloatingActionButton(
              onPressed: () async {
                print('Token onpr: $token');
                print('Class ID onpr: ${widget.classId}');
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateSurveyScreen(
                    token: widget.token,
                    classId: widget.classId,
                  )),
                );

                // Nếu result trả về true, thực hiện reload dữ liệu
                if (result == true) {
                  setState(() {
                    isReloading = true; // Set trạng thái reload
                    loadAssignments();
                  });
                  // Thực hiện reload dữ liệu ở đây (ví dụ gọi API hoặc load lại dữ liệu)
                  await reloadAssignments(token, classId);
                  setState(() {
                    isReloading = false; // Tắt trạng thái reload
                  });
                }
              }, // Hàm để thêm mục mới vào danh sách
              child: Icon(Icons.add),
              backgroundColor: Color(0xFFC02135),
              foregroundColor: Color(0xFFF2C209),
            ),
          ),
        ],
      ),
    );
  }
  void _showEditDialog(BuildContext context, Assignment assignItem) {
    final titleController = TextEditingController(text: assignItem.title);
    final descriptionController = TextEditingController(text: assignItem.description);
    final deadlineController = TextEditingController(text: assignItem.deadline.toString());
    print('adc: ${assignItem.fileUrl.runtimeType}');


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
          final  String formattedDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(fullDateTime);

          // Cập nhật trường Deadline
          setState(() {
            deadlineController.text = formattedDate;
          });
        }
      }
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Chỉnh sửa Assignment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              // Thêm các trường khác nếu cần
              const SizedBox(height: 16),
              TextField(
                controller: deadlineController,
                onTap: () => _selectDateTime(context),
                decoration: InputDecoration(labelText: 'Deadline (YYYY-MM-DDTHH:MM:SS)'),
              ),
              const SizedBox(height: 16),
              Text('File hiện tại: ${selectedFile ?? 'Không có file'}', style: TextStyle(color: Colors.blue)),
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

            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                // Call API to delete assignment
                _deleteAssignment(assignItem.id.toString());
                Navigator.pop(context);
              },
              child: Text('Xóa'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            TextButton(
              onPressed: () {
                if (selectedFile == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please select a file before saving.")),
                  );
                } else {
                  saveChange(
                    assignItem.id.toString(),
                    widget.token,
                    titleController.text,
                    descriptionController.text,
                    deadlineController.text,
                    selectedFile! ,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text('Lưu'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        );
      },
    );
  }
  Future<void> saveChange(String id, String token, String? title, String? description, String? deadline, File selectedFile ) async {
    if (selectedFile == null  ) {

      print('selectedFile: $selectedFile');
      print(" file is missing");
      return;
    }
    print('token: $token');
    if (selectedFile == null) {
      print("Please select a file before saving.");
      // Hiển thị thông báo lỗi cho người dùng
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Vui lòng chọn file trước khi lưu thay đổi!")),
      );
      return;
    }
    try{
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://160.30.168.228:8080/it5023e/edit_survey?file"),
      );
      request.fields['token'] = widget.token;
      request.fields['assignmentId'] = id;
      if (title != null) request.fields['title'] = title;
      if (title != null) request.fields['title'] = title;
      if (deadline != null) request.fields['deadline'] = deadline;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          selectedFile!.path,
        ),
      );
      print('token: ${widget.token}');
      print('id: $id');
      print('title: $title');
      print('description: $description');
      print('deadline: $deadline');
      print('file: $selectedFile');
      var response = await request.send();
      if (response.statusCode == 200) {
        print("Assignment updated successfully");
        if (response.statusCode == 200) {
          print("Assignment updated successfully");
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Cập nhật thành công")),);
        }
      } else {
        print('Failed to save change assignment. Status code: ${response.statusCode}');
        print('Response body: ${await response.stream.bytesToString()}');
      }
    } catch (e,stactrace){ {
      print("Error: $e");
      print("StackTrace: $stactrace");
    }
  }
  }

  Future<void> _deleteAssignment(String id) async {
    print('Xóa assignment: $id');
    print('Token: $widget.token');
    try {
      var response = await http.post(
        Uri.parse('http://160.30.168.228:8080/it5023e/delete_survey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "token": widget.token,  // Thay bằng token thực tế
          "survey_id": id,
        }),
      );
      if (response.statusCode == 200) {
        print('Xóa assignment thành công');
        setState(() {
          // Xóa bài viết khỏi danh sách của bạn
          loadAssignments();
        });
      } else {
        print('Lỗi xóa assignment: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi xóa assignment: $e');
    }
  }

  Widget _buildAssignmentCard(Assignment assignItem) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Xử lý sự kiện khi bấm vào Card
          print('Card tapped: ${assignItem.title}');
          _showEditDialog(context, assignItem);
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignItem.title ?? 'No Title',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                assignItem.description ?? 'No Description',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              if (assignItem.deadline != null) ...[
                SizedBox(height: 8),
                Text(
                  "Deadline: ${assignItem.deadline.toLocal().toString().split(
                      ' ')[0]}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red[400],
                  ),
                ),
              ],
              if (assignItem.fileUrl != null) ...[
                SizedBox(height: 8),
                Text(
                  "File: ${assignItem.fileUrl}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}