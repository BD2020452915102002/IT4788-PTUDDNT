import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/config/api_class.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/hive.dart';
import '../../../../core/utils/token.dart';

class AttendanceRecordScreen extends StatefulWidget {
  final String classId;
  const AttendanceRecordScreen({super.key, required this.classId});

  @override
  State<AttendanceRecordScreen> createState() => _AttendanceRecordScreenState();
}

class _AttendanceRecordScreenState extends State<AttendanceRecordScreen> {
  List<String> absentDates = [];
  bool isLoading = false;
  final TextEditingController _absenceCountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchAttendanceRecord();
  }

  Future<void> showError(response) async {
    if (response.statusCode == 400) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Bad Request!")));
    } else {
      final data = json.decode(response.body);
      final errorMessage = data['meta']['message'];
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));

      if (data['meta']['code'] == 9998) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
        await _logout();
      }
    }
  }

  Future<void> _logout() async {
    HiveService().clearBox();
    Navigator.pushNamed(context, '/login');
  }

  Future<void> fetchAttendanceRecord() async {
    setState(() {
      isLoading = true;
    });
    final response = await ApiClass().post('/get_attendance_record', {
      "token": Token().get(),
      "class_id": widget.classId,
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      print('duc $responseData');
      setState(() {
        absentDates =
            List<String>.from(responseData['data']['absent_dates'] ?? []);
        _absenceCountController.text =
            absentDates.length.toString(); // Cập nhật số ngày nghỉ
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      showError(response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Record'),
        backgroundColor: AppColors.primary,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _absenceCountController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Total Absences',
                      border: OutlineInputBorder(),
                      fillColor: AppColors.tertiary,
                      filled: true,
                    ),
                  ),
                ),
                Expanded(
                  child: absentDates.isEmpty
                      ? const Center(
                          child: Text('No absent dates found.'),
                        )
                      : ListView.builder(
                          itemCount: absentDates.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.event_busy,
                                  color: Colors.red),
                              title: Text(absentDates[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
