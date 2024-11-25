import 'package:flutter/material.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'dart:convert';
import '../../../core/utils/token.dart';
import '../../../core/config/api_class.dart';
import '../../../core/constants/colors.dart';

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

  bool isLoading = false;
  bool isLoading2 = false;

  List<String> _dateList = ['2024-11-25', '2024-11-26', '2024-11-27', '2024-11-25', '2024-11-26', '2024-11-27']; // Example date list
  String? _selectedDate; // To hold the selected value

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
        _dateNow = _date;
        _dateList = List<String>.from(Set<String>.from(_dateList));
        fetchStudents();
        fetchAttendanceDate();
      });
    });
  }

  Future<void> fetchStudents() async {
    setState(() {
      students = [];
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
        var responseBody = utf8.decode(response.bodyBytes); // Decode the body as UTF-8
        students = List<Map<String, dynamic>>.from(
          json.decode(responseBody)["data"]["student_accounts"],
        );
      });
    } else {
      setState(() {
        isLoading = false;
      });
      showError(response);
    }
  }

  Future<void> fetchAttendanceDate() async {
    setState((){
      isLoading2 = true;
      _dateList = [];
    });

    final response = await ApiClass().post('/get_attendance_dates', {
      'token': _token,
      'class_id': _classId
    });

    if(response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if(responseData['data'] != null) {
        setState(() {
          _dateList = List<String>.from(responseData["data"]);
        });
      }
      setState(() {
        isLoading2 = false;
      });
    } else {
      setState(() {
        isLoading2 = false;
      });
      showError(response);
    }


  }

  Future<void> fetchAttendanceData() async {
    setState(() {
      isLoading2 = true; // Show loading indicator
      attendanceDetails.clear();
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
              orElse: () => {},
            );
            if (student.isNotEmpty) {
              attendance['first_name'] = student['first_name'];
              attendance['last_name'] = student['last_name'];
            }
          }

          isLoading2 = false;
        });
      } else {
        setState(() {
          isLoading2 = false;
        });
      }
    } else {
      setState(() {
        isLoading2 = false;
      });
      showError(response);
    }
  }

  Future<void> changeAbsenceStatus(attendanceId, status) async {
    setState(() {
      isLoading2 = true;
    });
    final response = await ApiClass().post('/set_attendance_status', {
      "token": _token,
      "status": status.toString(),
      "attendance_id": attendanceId.toString()
    });

    if (response.statusCode == 200) {
      setState(() {
        isLoading2 = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Change Status Successfully')),
      );

    } else {
      setState(() {
        isLoading2 = false;
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

  // Submit Absences
  Future<void> submitAbsences() async {
    setState((){
      isLoading = true;
    });
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

      setState((){
        isLoading = false;
        absenceList.clear();
      });

      fetchAttendanceDate();
    } else {
      setState((){
        isLoading = false;
      });
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
    double absenceColumnWidth = screenWidth * 0.2; // 20% of screen width
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
                                          checkColor: Colors.white, // Color of the checkmark
                                          activeColor: AppColors.primary50, // Color when checked
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,  // Align the button to the right
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            showLoadingDialog(context);
                            await submitAbsences();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.buttonColor,  // Button background color
                            foregroundColor: Colors.white,  // Text color for the button
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),  // Set the border radius here
                            ),
                          ),
                          child: Text('Gửi'),
                        ),
                        SizedBox(width: 8.0),
                      ],
                    )
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
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Padding for button-like appearance
                              decoration: BoxDecoration(
                                color: Colors.white, // Set the background color to white
                                borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                border: Border.all(color: AppColors.primary50), // Border color
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26, // Shadow color
                                    blurRadius: 4.0, // Blur radius
                                    offset: Offset(0, 2), // Shadow position
                                  ),
                                ], // Adding shadow
                              ),
                              height: 50, // Fixed height for the dropdown button
                              child: Center( // Center the dropdown text inside the button
                                child: DropdownButtonHideUnderline( // Hide the default underline of Dropdown
                                  child: DropdownButton<String>(
                                    hint: Text(
                                      'Select Date',
                                      style: TextStyle(
                                        color: AppColors.textColorBlur,
                                        fontWeight: FontWeight.bold, // Make hint text bold
                                      ),
                                    ),
                                    value: _selectedDate, // This is the selected date from the list
                                    onChanged: (String? newValue) {
                                      if (newValue != _selectedDate) {
                                        setState(() {
                                          _selectedDate = newValue;
                                          _date = (_selectedDate).toString();
                                          fetchAttendanceData();
                                        });
                                      }
                                    },
                                    items: _dateList.map<DropdownMenuItem<String>>((String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Center( // Center the text inside each item
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              color: AppColors.textColor,
                                              fontWeight: FontWeight.bold, // Make the dropdown items bold
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    icon: Icon(
                                      Icons.calendar_today,
                                      color: AppColors.primary50, // Icon color
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textColor,
                                      fontWeight: FontWeight.bold, // Make the selected text bold
                                    ),
                                    isExpanded: true, // Expand to fill available space
                                    isDense: true, // Reduce vertical space
                                    menuMaxHeight: 200, // Set max height for dropdown items
                                    dropdownColor: Colors.white, // Set dropdown background color
                                    selectedItemBuilder: (BuildContext context) {
                                      return _dateList.map<Widget>((String value) {
                                        return Center( // Center the selected text inside the dropdown button
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              fontSize: 16.0,
                                              color: AppColors.textColor,
                                              fontWeight: FontWeight.bold, // Make the selected text bold
                                            ),
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
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

                          isLoading2
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
                                border: TableBorder.all(color: Colors.grey),
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
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: attendance['status'],
                                              onChanged: (newValue) {
                                                setState(() {
                                                  attendance['status'] = newValue;
                                                  changeAbsenceStatus(attendance['attendance_id'], newValue);
                                                });
                                              },
                                              items: const [
                                                DropdownMenuItem(
                                                  value: 'EXCUSED_ABSENCE',
                                                  child: Text(
                                                    'Có Phép',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.yellow,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'UNEXCUSED_ABSENCE',
                                                  child: Text(
                                                    'Không phép',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 12.0,
                                                      color: AppColors.primary50,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: 'PRESENT',
                                                  child: Text(
                                                    'Có mặt',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      fontSize: 12.0,
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
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
