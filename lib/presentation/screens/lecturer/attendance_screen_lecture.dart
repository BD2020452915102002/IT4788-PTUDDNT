import 'package:flutter/material.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'dart:convert';
import '../../../core/utils/token.dart';
import '../../../core/config/api_class.dart';
import '../../../core/constants/colors.dart';  // Import AppColors class

class AttendanceLectureScreen extends StatefulWidget {
  final String classId;
  const AttendanceLectureScreen({super.key, required this.classId});
  @override
  State<AttendanceLectureScreen> createState() => _AttendanceLecturerState();
}

class _AttendanceLecturerState extends State<AttendanceLectureScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> students = [];
  List<Map<String, dynamic>> attendanceDetails = [];
  List<String> absenceList = [];

  String _token = '';
  String _date = '';
  String _dateNow = '';
  String _classId = '';
  final TextEditingController _dateController = TextEditingController();

  int? sortColumnIndex1;
  bool sortAscending1 = true;
  int? sortColumnIndex2;
  bool sortAscending2 = true;

  late TabController _tabController;
  final FocusNode _dateFocusNode = FocusNode();

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

    _classId = widget.classId;
    getToken().then((_) {
      setState(() {
        _date = formatDate(DateTime.now());
        _dateController.text = _date;
        _dateNow = _date;
        fetchStudents();
      });
    });
  }

  Future<void> fetchStudents() async {
    setState(() {
      isLoading = true;
    });
    final response = await ApiClass().post('/get_class_info', {
      "token": _token,
      "class_id": _classId,
      "role": "LECTURER",
      "account_id": 2,
    });

    if (response.statusCode == 200) {

      setState(() {
        isLoading = false;
        students = List<Map<String, dynamic>>.from(
          json.decode(response.body)["data"]["student_accounts"],
        );
      });
    } else {
      setState(() {
        isLoading = false;
      });
      showError(response);
    }
  }

  Future<void> fetchAttendanceData() async {
    setState(() {
      isLoading = true; // Show loading indicator
      attendanceDetails.clear();
      _date = _dateController.text;
      print("date:" + _date);
    });

    final response = await ApiClass().post('/get_attendance_list', {
      'token': _token,
      'class_id': _classId,
      'date': _date.toString(),
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
    setState(() {
      isLoading = true;
    });
    final response = await ApiClass().post('/set_attendance_status', {
      "token": _token,
      "status": status.toString(),
      "attendance_id": attendanceId.toString()
    });

    if (response.statusCode == 200) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Change Status Successfully')),
      );

    } else {
      setState(() {
        isLoading = false;
      });
      showError(response);

    }
  }

  Future<void> showError(response) async {
    final data = json.decode(response.body);
    final errorMessage = data['meta']['message'];
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));

    if (data['meta']['code'] == 9998) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage)));
      _logout();
    }
  }

  Future<void> _logout() async {
    HiveService().clearBox();
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      "/login",
          (Route<dynamic> route) => false,
    );
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

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _dateController.text = pickedDate.toLocal().toString().split(' ')[0];
      });
      print(_dateController.text);
      // Format as YYYY-MM-DD
    }
  }

  // Submit Absences
  Future<void> submitAbsences() async {
    final response = await ApiClass().post('/take_attendance', {
      "token": _token,
      "class_id": _classId,
      "date": _dateNow,
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

  void _sortTable1(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex1 = columnIndex;
      sortAscending1 = ascending;

      // Sort by student_id if columnIndex is 0
      if (columnIndex == 0) {
        students.sort((a, b) {
          return ascending
              ? a['student_id'].compareTo(b['student_id'])
              : b['student_id'].compareTo(a['student_id']);
        });
      }
      // Sort by Name if columnIndex is 1
      if (columnIndex == 1) {
        students.sort((a, b) {
          final nameA = '${a['first_name']} ${a['last_name']}';
          final nameB = '${b['first_name']} ${b['last_name']}';
          return ascending
              ? nameA.compareTo(nameB)
              : nameB.compareTo(nameA);
        });
      }
    });
  }

  void _sortTable2(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex2 = columnIndex;
      sortAscending2 = ascending;

      // Sort by student_id if columnIndex is 0
      if (columnIndex == 0) {
        attendanceDetails.sort((a, b) {
          return ascending
              ? a['student_id'].compareTo(b['student_id'])
              : b['student_id'].compareTo(a['student_id']);
        });
      }
      // Sort by Name if columnIndex is 1
      if (columnIndex == 1) {
        attendanceDetails.sort((a, b) {
          final nameA = '${a['first_name']} ${a['last_name']}';
          final nameB = '${b['first_name']} ${b['last_name']}';
          return ascending
              ? nameA.compareTo(nameB)
              : nameB.compareTo(nameA);
        });
      }
    });
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
    double screenWidth = MediaQuery.of(context).size.width;

    // Calculate column widths as percentages of the screen width
    double indexColumnWidth = screenWidth * 0.1;
    double idColumnWidth = screenWidth * 0.2;   // 20% of screen width
    double nameColumnWidth = screenWidth * 0.5; // 50% of screen width
    double absenceColumnWidth = screenWidth * 0.2; // 30% of screen width
    return Scaffold(
      appBar: AppBar(
        title: const Text('ĐIỂM DANH'),
        centerTitle: true,
        foregroundColor: AppColors.tertiary,
        backgroundColor: AppColors.primary,  // Applying custom primary color
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelStyle: TextStyle(color: AppColors.secondary),
          unselectedLabelColor: Colors.grey,  // Color for unselected tab text
          tabs: const [
            Tab(text: "Điểm danh"),
            Tab(text: "Cập nhật điểm danh"),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    Table(
                      columnWidths: {
                        0: FixedColumnWidth(indexColumnWidth),
                        1: FixedColumnWidth(idColumnWidth),
                        2: FixedColumnWidth(nameColumnWidth),
                        3: FixedColumnWidth(absenceColumnWidth),
                      },
                      border: TableBorder.all(color: AppColors.tertiary), // Add border to table
                      children: [
                        // Table Header with sorting functionality
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blue), // Header row background color
                          children: [
                            SizedBox(
                              height: 50, // Header row height
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        'ID',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white),
                                      ),
                                    ),
                                  ),

                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _sortTable1(0, !sortAscending1);
                              },
                              child: SizedBox(
                                height: 50, // Header row height
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'MSSV',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      sortColumnIndex1 == 0
                                          ? (sortAscending1
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward)
                                          : null,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                _sortTable1(1, !sortAscending1);
                              },
                              child: SizedBox(
                                height: 50, // Header row height
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Họ và tên',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      sortColumnIndex1 == 1
                                          ? (sortAscending1
                                          ? Icons.arrow_upward
                                          : Icons.arrow_downward)
                                          : null,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                                height: 50, // Header row height
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Center(
                                        child: Text(
                                          'Vắng',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                              ),

                          ],
                        ),
                      ],
                    ),
                    SizedBox(

                      height: 300,
                      width: MediaQuery.of(context).size.width,
                      child: isLoading ? Center(child: CircularProgressIndicator())
                          :
                          Expanded(
                            child: SingleChildScrollView(
                            child: Table(
                              columnWidths: {
                                0: FixedColumnWidth(indexColumnWidth),
                                1: FixedColumnWidth(idColumnWidth),  // ID column width = 100
                                2: FixedColumnWidth(nameColumnWidth),  // Name column width = 200
                                3: FixedColumnWidth(absenceColumnWidth),  // Absence column width = 100
                              },
                              border: TableBorder.all(color: Colors.grey),
                              children: students.asMap().entries.map((entry) {
                                final index = entry.key;   // This gives you the index of the student
                                final student = entry.value; // This gives you the student data
                                Color boxColor = (index % 2 == 0 ? Colors.white : AppColors.tertiary);

                                return TableRow(
                                  decoration: BoxDecoration(color: boxColor),
                                  children: [
                                    SizedBox(
                                      height: 50,
                                      child: Center(child: Text((index+ 1).toString())),
                                    ),
                                    SizedBox(
                                      height: 50, // Row height
                                      child: Center(child: Text(student['student_id']!)),
                                    ),
                                    SizedBox(
                                      height: 50, // Row height
                                      child: Center(child: Text('${student['first_name']} ${student['last_name']}')),
                                    ),
                                    SizedBox(
                                      height: 50, // Row height
                                      child: Center(
                                        child: Checkbox(
                                          value: absenceList.contains(student['student_id']),
                                          onChanged: (value) => _onCheckboxChanged(value, student['student_id']),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),

                          ),

                    ),
                    SizedBox(height: 20),
                    Table(

                        columnWidths: {
                          0: FixedColumnWidth(indexColumnWidth),
                          1: FixedColumnWidth(idColumnWidth + nameColumnWidth),
                          2: FixedColumnWidth(absenceColumnWidth),
                        },
                        border: TableBorder.all(color: AppColors.tertiary), // Add border to table
                        children: [
                          // Table Header
                          TableRow(
                            decoration: BoxDecoration(color: Colors.blue), // Header row background color

                            children: [
                              SizedBox(
                                height: 50, // Header row height
                                child: Center(child: Text('Tổng', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                              ),
                              SizedBox(
                                height: 50, // Header row height
                                child: Center(child: Text("Số SV: " + students.length.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                              ),
                              SizedBox(
                                height: 50, // Header row height
                                child: Center(child: Text(absenceList.length.toString(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                              ),
                            ],
                          ),
                        ]
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        showLoadingDialog(context);
                        await submitAbsences();
                        Navigator.of(context).pop();

                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,  // Button background color
                        foregroundColor: Colors.white,  // Text color for the button
                      ), // Custom button color
                      child: Text('Gửi'),
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
                            child: GestureDetector(
                              onTap: () async {
                                _dateFocusNode.unfocus(); // Close the keyboard if open
                                await _pickDate(context); // Show date picker
                              },
                              behavior: HitTestBehavior.translucent, // Ensures taps are properly registered
                              child: AbsorbPointer( // Prevent default TextField tap behavior
                                child: TextField(
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Nhập ngày',
                                    hintText: 'YYYY-MM-DD',
                                    hintStyle: TextStyle(color: AppColors.textColorBlur),
                                    border: OutlineInputBorder(),
                                    suffixIcon: Icon(Icons.calendar_today),
                                    fillColor: AppColors.tertiary,
                                  ),
                                  controller: _dateController,
                                  focusNode: _dateFocusNode,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.search, color: AppColors.primary50),
                            onPressed: () async {
                              _dateFocusNode.unfocus();
                              fetchAttendanceData();
                            },
                          ),

                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Ensures that the Column doesn't take extra space
                        children: [
                          // Table Header with sorting functionality
                          Table(
                            columnWidths: {
                              0: FixedColumnWidth(indexColumnWidth),
                              1: FixedColumnWidth(idColumnWidth),
                              2: FixedColumnWidth(nameColumnWidth),
                              3: FixedColumnWidth(absenceColumnWidth),
                            },
                            border: TableBorder.all(color: AppColors.tertiary),
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.blue),
                                children: [
                                  SizedBox(
                                    height: 50,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              'ID',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _sortTable2(0, !sortAscending2);
                                    },
                                    child: SizedBox(
                                      height: 50,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                'MSSV',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            sortColumnIndex2 == 0
                                                ? (sortAscending2
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward)
                                                : null,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _sortTable2(1, !sortAscending2);
                                    },
                                    child: SizedBox(
                                      height: 50,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                'Họ và tên',
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            sortColumnIndex2 == 1
                                                ? (sortAscending2
                                                ? Icons.arrow_upward
                                                : Icons.arrow_downward)
                                                : null,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 50,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Center(
                                            child: Text(
                                              'Vắng',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          isLoading
                              ? Center(child: CircularProgressIndicator())
                              : SizedBox(
                            height: 350,
                            child: SingleChildScrollView(
                              child: Table(
                                columnWidths: {
                                  0: FixedColumnWidth(indexColumnWidth),
                                  1: FixedColumnWidth(idColumnWidth),  // ID column width = 100
                                  2: FixedColumnWidth(nameColumnWidth),  // Name column width = 200
                                  3: FixedColumnWidth(absenceColumnWidth),  // Absence column width = 100
                                },
                                border: TableBorder.all(color: AppColors.textColor),
                                children: attendanceDetails.asMap().entries.map((entry) {
                                  final index = entry.key;   // This gives you the index of the student
                                  final attendance = entry.value; // This gives you the student data
                                  Color boxColor = (index % 2 == 0 ? Colors.white : AppColors.tertiary);
                                  return TableRow(
                                    decoration: BoxDecoration(color: boxColor),
                                    children: [
                                      SizedBox(
                                        height: 50,  // Row height
                                        child: Center(child: Text((index + 1).toString())),
                                      ),
                                      SizedBox(
                                        height: 50,  // Row height
                                        child: Center(child: Text(attendance['student_id'].toString())),
                                      ),
                                      SizedBox(
                                        height: 50,  // Row height
                                        child: Center(child: Text('${attendance['first_name']} ${attendance['last_name']}')),
                                      ),
                                      SizedBox(
                                        height: 50,  // Row height
                                        child: Center(
                                          child: DropdownButton<String>(
                                            value: attendance['status'],
                                            onChanged: (newValue) {
                                              setState(() {
                                                attendance['status'] = newValue;
                                                changeAbsenceStatus(attendance['attendance_id'], newValue);
                                              });
                                            },
                                            items: const [
                                              DropdownMenuItem(value: 'EXCUSED_ABSENCE', child: Text('Có Phép',
                                                                                                      textAlign: TextAlign.center,
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 12.0,
                                                                                                        color: Colors.yellow
                                                                                                      ))),
                                              DropdownMenuItem(value: 'UNEXCUSED_ABSENCE', child: Text('Không phép',
                                                                                                      textAlign: TextAlign.center,
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 12.0,
                                                                                                        color: AppColors.primary50
                                                                                                      ))),
                                              DropdownMenuItem(value: 'PRESENT', child: Text('Có mặt',
                                                                                                      textAlign: TextAlign.center,
                                                                                                      style: TextStyle(
                                                                                                        fontSize: 12.0,
                                                                                                        color: Colors.green
                                                                                                      ))),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),

                            ),
                          ),
                          Table(

                          ),
                        ],
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
