import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/colors.dart';
import '../../../../data/models/assign.dart';
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

  @override
  void initState() {
    super.initState();
    loadAssignments();
    reloadAssignments(widget.token,widget.classId as String);
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
        "token": token,
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
              onPressed: (){
                print('Token onpr: $token');
                print('Class ID onpr: ${widget.classId}');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CreateSurveyScreen(
                    token: widget.token,
                    classId: widget.classId,)),

                );
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