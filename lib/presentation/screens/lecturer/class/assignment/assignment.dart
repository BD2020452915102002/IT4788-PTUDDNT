import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ptuddnt/data/models/assign.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/hive.dart';
import '../../../../../data/models/material.dart';
import 'creat_assignment.dart';
import 'edit_assignment.dart';

class AssignmentScreen extends StatefulWidget {
  final String token;
  final String classId;
  const AssignmentScreen({Key? key, required this.token, required this.classId}) : super(key: key);
  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}
class _AssignmentScreenState extends State<AssignmentScreen> {
  bool isLoading = true;
  bool isReloading = false;
  List<Assignment> assignments = [];
  List<Assignment> ongoingAssignments = [];
  List<Assignment> expiredAssignments = [];

  @override
  void initState() {
    super.initState();
    _init();
    ongoingAssignments = assignments.where((assignment) {
      return assignment.deadline.isAfter(DateTime.now());
    }).toList();

    expiredAssignments = assignments.where((assignment) {
      return assignment.deadline.isBefore(DateTime.now());
    }).toList();
  }
  Future<void> _init () async {
    final bt = HiveService().getData('baitap');
    if ( bt == null ){
      await loadAssign();
    }
    setState(() {
      assignments = (HiveService().getData('baitap') as List).map((json) => Assignment.fromJson(json)).toList();
      isLoading = false;
    });
  }
  Future<void> loadAssign() async {
    assignments = await fetchAssignment(widget.token, widget.classId );
  }
  Future<List<Assignment>> fetchAssignment(String token, String classId) async {
    final String apiUrl = 'http://157.66.24.126:8080/it5023e/get_all_surveys';

    try {
      final body = json.encode({
        'token': widget.token,
        'class_id': widget.classId,
      });

      // Thực hiện POST request
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );
      print('Token in fetchAssign: ${widget.token}');
      print('Class ID in fetchAssign: ${widget.classId}');

      // Kiểm tra trạng thái phản hồi
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));

        if (jsonResponse != null && jsonResponse['data'] != null) {
          await HiveService().saveData('baitap', jsonResponse['data']);
        }
      } else {
        throw Exception('Failed to fetch assignments: ${response.statusCode} - ${response.body}');
      }
    } catch (error) {
      throw Exception('Error fetching assignments: $error');
    }
    return [];
  }
  Future<void> reloadData() async {
    try {
      // Lấy dữ liệu hiện tại từ Hive
      final currentData = HiveService().getData('tailieu');
      print('Current Hive Data: $currentData');

      // Xóa dữ liệu cũ trong Hive
      await HiveService().saveData('tailieu', null);
      print('Old data removed from Hive.');

      // Tải dữ liệu mới từ API
      await fetchAssignment(widget.token, widget.classId);
      print('New data fetched from API.');

      // Lấy dữ liệu mới từ Hive
      final newData = HiveService().getData('tailieu');
      setState(() {
        assignments = (HiveService().getData('baitap') as List).map((json) => Assignment.fromJson(json)).toList();
        isLoading = false;
      });

      print('New data loaded to screen: ${assignments.length} items.');
    } catch (e) {
      print('Error in reloadData: $e');
    }
  }
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }
  Future<void> _deleteAssignmnet(int id) async {
    print('Xóa Assign: $id');
    print('Token in delete: ${widget.token}');
    try {
      var response = await http.post(
        Uri.parse('http://157.66.24.126:8080/it5023e/delete_survey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "token": widget.token,  // Thay bằng token thực tế
          "survey_id": id,
        }),
      );
      if (response.statusCode == 200) {
        print('Xóa Assign thành công');

        setState(() {
          fetchAssignment(widget.token, widget.classId);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Xóa thành công')),
          );
          Navigator.pop(context);
        });
      } else {
        print('Lỗi xóa assignmet: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi xóa assgnment  : $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    final ongoingAssignments = assignments.where((assignment) {
      return assignment.deadline.isAfter(DateTime.now());
    }).toList();

    final expiredAssignments = assignments.where((assignment) {
      return assignment.deadline.isBefore(DateTime.now());
    }).toList();

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
          "Assignment",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: reloadData, // Hàm làm mới dữ liệu
        child: Stack(
          children: [
            isLoading
                ? Center(child: CircularProgressIndicator())
                : assignments.isEmpty
                ? Center(child: Text("No Assignment found."))
                : ListView(
              children: [
                if (ongoingAssignments.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(
                        top: 10.0, left: 10.0, right: 16.0),
                    child: Text(
                      "Đang trong quá trình",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: ongoingAssignments.length,
                    itemBuilder: (context, index) {
                      final assignment = ongoingAssignments[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          title: Text(assignment.title),
                          subtitle: Text(assignment.description),
                          trailing: Text(
                            assignment.deadline
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                          ),
                          onTap: () {
                            _showAssignmentDetailsDialog(assignment);
                          },
                        ),
                      );
                    },
                  ),
                ],
                if (expiredAssignments.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.only(
                        top: 10.0, left: 10.0, right: 16.0),
                    child: Text(
                      "Đã hết hạn",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: expiredAssignments.length,
                    itemBuilder: (context, index) {
                      final assignment = expiredAssignments[index];
                      return Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: ListTile(
                          title: Text(assignment.title),
                          subtitle: Text(assignment.description),
                          trailing: Text(
                            assignment.deadline
                                .toLocal()
                                .toString()
                                .split(' ')[0],
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () {
                            _showAssignmentDetailsDialog(assignment);
                          },
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            Positioned(
              bottom: 50.0,
              right: 20.0,
              child: FloatingActionButton(
                onPressed: () async {
                  print('Token press: ${widget.token}');
                  print('Class ID press create: ${widget.classId}');
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateSurveyScreen(
                        token: widget.token,
                        classId: widget.classId,
                      ),
                    ),
                  );
                  if (result == true) {
                    setState(() {
                      isReloading = true; // Set trạng thái reload
                      loadAssign();
                    });
                  }
                },
                child: Icon(Icons.add),
                backgroundColor: Color(0xFFC02135),
                foregroundColor: Color(0xFFF2C209),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _showAssignmentDetailsDialog(Assignment assignment) {
    String formattedDate = DateFormat('HH:mm dd/MM/yyyy').format(assignment.deadline);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Container(
            padding: EdgeInsets.all(10),
            color: Color(0xFFC02135), // Đặt màu nền đỏ//
            child: Center(
              child: Text(
                assignment.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black), // Màu mặc định cho toàn bộ văn bản
                  children: [
                    TextSpan(
                      text: 'Description: ', // Phần "Description" được in đậm
                      style: TextStyle(
                        fontWeight: FontWeight.bold, // Làm đậm chữ "Description"
                        color: Colors.black, // Màu của "Description"
                      ),
                    ),
                    TextSpan(
                      text: assignment.description, // Phần mô tả không thay đổi
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black),
                  children: [
                    TextSpan(
                      text: 'Deadline: ', // "Deadline" in đậm
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    TextSpan(
                      text: formattedDate, // Ngày giờ định dạng
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        color: assignment.deadline.isBefore(DateTime.now())
                            ? Colors.red // Màu đỏ nếu deadline đã qua
                            : Colors.green, // Màu xanh nếu deadline chưa đến
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.black), // Màu mặc định cho toàn bộ text
                  children: [
                    TextSpan(
                      text: 'Assignment Link: ', // In đậm và màu đen
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          if (assignment.assignmentLink != null && assignment.assignmentLink!.isNotEmpty) {
                            _launchURL(assignment.assignmentLink!); // Gọi hàm mở link
                          }
                        },
                        child: Text(
                          assignment.assignmentLink != null && assignment.assignmentLink!.isNotEmpty
                              ? assignment.assignmentLink!
                              : 'N/A', // Hiển thị "N/A" nếu link bị null hoặc rỗng
                          style: TextStyle(
                            color: assignment.assignmentLink != null && assignment.assignmentLink!.isNotEmpty
                                ? Colors.blue
                                : Colors.grey, // Đổi màu xám nếu link không khả dụng
                            decoration: assignment.assignmentLink != null && assignment.assignmentLink!.isNotEmpty
                                ? TextDecoration.underline
                                : TextDecoration.none, // Không gạch chân nếu link không khả dụng
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Đóng"),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            TextButton(
              onPressed: () {
                // Call API to delete assignment
                _deleteAssignmnet(assignment.id );
                Navigator.pop(context);
              },
              child: Text('Xóa'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Xác nhận'),
                      content: Text('Bạn phải cập nhật lại file nếu muốn tiếp tục sửa.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Đóng dialog
                          },
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditAssignmentScreen(
                                  token: widget.token,
                                  assignmentId: assignment.id ,
                                  title: assignment.title,  // Truyền title
                                  description: assignment.description,  // Truyền description
                                  deadline: assignment.deadline,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                setState(() {
                                  isReloading = true; // Set trạng thái reload
                                  loadAssign();
                                });
                              }
                            });
                          },
                          child: Text('Đồng ý'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Edit'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),

          ],
        );
      },
    );
  }

}