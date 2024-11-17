import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../../core/config/api_class.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/token.dart';

class AttendanceRecordScreen extends StatefulWidget {
  const AttendanceRecordScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceRecordScreen> createState() => _AttendanceRecordScreenState();
}

class _AttendanceRecordScreenState extends State<AttendanceRecordScreen> {
  List<String> absentDates = [];
  bool isLoading = false;
  TextEditingController _absenceCountController = TextEditingController();

  String _token ='';
  @override
  void initState() {
    super.initState();
    _getToken().then((_) {
      fetchAttendanceRecord();
    });

  }

  Future<void> _getToken() async {
    _token = (await Token().get())!;
  }

  Future<void> fetchAttendanceRecord() async {
    setState(() {
      isLoading = true;
    });

    final response = await ApiClass().post('/get_attendance_record', {
      "token": _token,
      "class_id": "001511",
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      setState(() {
        absentDates = List<String>.from(responseData['data']['absent_dates'] ?? []);
        _absenceCountController.text = absentDates.length.toString(); // Cập nhật số ngày nghỉ
        isLoading = false;
      });
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
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
                  leading: const Icon(Icons.event_busy, color: Colors.red),
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
