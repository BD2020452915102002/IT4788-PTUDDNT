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

  Future<void> _logout() async {
    HiveService().clearBox();
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      "/login",
          (Route<dynamic> route) => false,
    );
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

  Color _getAbsenceColor(int absenceCount) {
    if (absenceCount > 3) {
      return Colors.red; // Red for > 3 absences
    } else if (absenceCount == 0) {
      return Colors.green; // Green for 0 absences
    } else {
      return Colors.yellow; // Yellow for 1-2 absences
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Theo dõi điểm danh', style: TextStyle(color: AppColors.tertiary)),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.tertiary, // Set back button color
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                  Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RichText(
                    text: TextSpan(
                      text: 'Số buổi nghỉ học: ',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor, // Base text color
                      ),
                      children: [
                        TextSpan(
                          text: '${_absenceCountController.text}', // Dynamically set the absence count

                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getAbsenceColor(int.tryParse(_absenceCountController.text) ?? 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: absentDates.isEmpty
                      ? const Center(
                          child: Text('Đi học đầy đủ :D.'),
                        )
                      : ListView.builder(
                          itemCount: absentDates.length,
                          itemBuilder: (context, index) {
                            Color boxColor = (index % 2 == 0 ? Colors.white : AppColors.tertiary);
                            return Container(
                              color: boxColor,

                              child: ListTile(
                                leading: const Icon(
                                  Icons.event_busy,
                                  color: Colors.red,
                                ),
                                title: RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Nghỉ học ngày ${index + 1}: ",
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                      TextSpan(
                                        text: absentDates[index],
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
