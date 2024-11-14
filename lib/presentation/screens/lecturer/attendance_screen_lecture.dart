import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/utils/token.dart';
import '../../../core/config/api_class.dart';
import '../../../core/constants/colors.dart';  // Import AppColors class

class AttendanceLectureScreen extends StatefulWidget {
  const AttendanceLectureScreen({super.key});
  @override
  State<AttendanceLectureScreen> createState() => _AttendanceLecturerState();
}

class _AttendanceLecturerState extends State<AttendanceLectureScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> attendanceDetails = [];
  List<String> absenceList = [];

  String _token = '';
  String _date = '';
  String _classId = '';
  final TextEditingController _dateController = TextEditingController();

  late TabController _tabController;

  bool isLoading = false;

  Future<void> getToken() async {
    _token = (await Token().get())!;
  }

  String formatDate(DateTime date) {
    String year = date.year.toString();
    String month = date.month.toString().padLeft(2, '0');
    String day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    getToken().then((_) {
      _classId = "001511"; // Static class ID for now
      _date = formatDate(DateTime.now());
      _dateController.text = _date;

      fetchStudents();
    });
  }

  Future<void> fetchStudents() async {
    final response = await ApiClass().post('/get_class_info', {
      "token": _token,
      "class_id": _classId,
      "role": "LECTURER",
      "account_id": 2,
    });

    if (response.statusCode == 200) {
      setState(() {
        students = List<Map<String, dynamic>>.from(
          json.decode(response.body)["data"]["student_accounts"],
        );
      });
    } else {
      showError(response);
    }
  }

  Future<void> fetchAttendanceData() async {
    setState(() {
      isLoading = true; // Show loading indicator
      attendanceDetails.clear();
      _date = _dateController.text;
    });

    final response = await ApiClass().post('/get_attendance_list', {
      'token': _token,
      'class_id': '001511',
      'date': _date,
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (responseData['data'] != null) {
        setState(() {
          attendanceDetails = List<Map<String, dynamic>>.from(responseData['data']['attendance_student_details']);

          for (var attendance in attendanceDetails) {
            var student = students.firstWhere(
                  (student) => student['student_id'] == attendance['student_id'],
              orElse: () => {}, // Empty map if no match is found
            );
            if (student.isNotEmpty) {
              // Add first_name and last_name from students to each attendance entry
              attendance['first_name'] = student['first_name'];
              attendance['last_name'] = student['last_name'];
            }
          }

          isLoading = false; // Hide loading indicator
        });
      } else {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    } else {
      setState(() {
        isLoading = false; // Hide loading indicator
      });
      showError(response);
    }
  }

  Future<void> changeAbsenceStatus(attendanceId, status) async {
    final response = await ApiClass().post('/set_attendance_status', {
      "token": _token,
      "status": status.toString(),
      "attendance_id": attendanceId.toString()
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Change Status Successfully')),
      );
    } else {
      showError(response);
    }
  }

  Future<void> showError(response) async {
    if(response.statusCode == 400){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bad Request!")));
    } else{
      final data = json.decode(response.body);
      final errorMessage = data['meta']['message'];
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));

      if (data['meta']['code'] == 9998) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
        await _logout();
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userData');

    Navigator.pushNamed(context, '/login');
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevents dialog from closing on outside touch
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Loading..."),
              ],
            ),
          ),
        );
      },
    );
  }

  // Submit Absences
  Future<void> submitAbsences() async {
    final response = await ApiClass().post('/take_attendance', {
      "token": _token,
      "class_id": _classId,
      "date": _date,
      "attendance_list": absenceList,
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Attendance Submitted Successfully')),
      );
      absenceList.clear();
    } else {
      showError(response);
    }
  }

  // Handle Checkbox Change for Absence List
  void _onCheckboxChanged(bool? value, String studentId) {
    setState(() {
      if (value == true) {
        absenceList.add(studentId);
      } else {
        absenceList.remove(studentId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Attendance'),
        backgroundColor: AppColors.primary,  // Applying custom primary color
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,  // Purple color for tab indicator
          labelStyle: TextStyle(color: AppColors.secondary),  // Purple color for selected tab text
          unselectedLabelColor: Colors.grey,  // Color for unselected tab text
          tabs: const [
            Tab(text: "Take Attendance"),
            Tab(text: "Update Attendance Status"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // "Take Attendance" Section
                Column(
                  children: [
                    SizedBox(
                      height: 400,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text("ID")),
                            DataColumn(label: Text("Name")),
                            DataColumn(label: Text("Student ID")),
                            DataColumn(label: Text("Absent")),
                          ],
                          rows: students.map((student) {
                            return DataRow(
                              cells: [
                                DataCell(Text(student['account_id'].toString())),
                                DataCell(Text('${student['first_name']} ${student['last_name']}')),
                                DataCell(Text(student['student_id'].toString())),
                                DataCell(
                                  Checkbox(
                                    value: absenceList.contains(student['student_id'].toString()),
                                    onChanged: (value) {
                                      _onCheckboxChanged(value, student['student_id'].toString());
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        showLoadingDialog(context);
                        await Future.delayed(Duration(seconds: 1));
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,  // Button background color
                        foregroundColor: Colors.white,  // Text color for the button
                      ), // Custom button color
                      child: Text('Submit'),
                    ),
                  ],
                ),

                // "Update Attendance Status" Section
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: 'Date',
                                hintText: 'YYYY-MM-DD',
                                hintStyle: TextStyle(color: AppColors.textColorBlur),
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                                fillColor: AppColors.tertiary,
                                filled: true,
                              ),
                              controller: _dateController,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: AppColors.primary50),  // Custom icon color
                            onPressed: () async {
                              fetchAttendanceData();
                            },
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('ID')),
                            DataColumn(label: Text('Name')),
                            DataColumn(label: Text('Student ID')),
                            DataColumn(label: Text('Absent')),
                          ],
                          rows: attendanceDetails.map((attendance) {
                            return DataRow(
                              cells: [
                                DataCell(Text(attendance['attendance_id'].toString())),
                                DataCell(Text('${attendance['first_name']} ${attendance['last_name']}')),
                                DataCell(Text(attendance['student_id'].toString())),
                                DataCell(
                                  Switch(
                                    value: attendance['status'] == 0 ? false : true,
                                    onChanged: (value) {
                                      changeAbsenceStatus(
                                        attendance['attendance_id'],
                                        value ? 1 : 0,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
