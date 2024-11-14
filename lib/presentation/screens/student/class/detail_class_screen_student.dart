import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';

class DetailClassScreenStudent extends StatelessWidget {
  final Map<String, dynamic> classData;

  const DetailClassScreenStudent({super.key, required this.classData});

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
          classData['class_name'],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 20.0,
          childAspectRatio: 1.5,
          children: [
            _ClassInfoButton(),
            _ViewMaterialsButton(),
            _AssignmentsButton(classData: classData),
            _AttendanceButton(),
            _RequestLeaveButton(),
          ],
        ),
      ),
    );
  }
}

class _ClassInfoButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Logic khi nhấn vào "Thông tin lớp học"
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.class_, 'Thông tin lớp học'),
    );
  }
}

class _ViewMaterialsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Logic khi nhấn vào "Xem tài liệu môn học"
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.share, 'Xem tài liệu môn học'),
    );
  }
}

class _AssignmentsButton extends StatelessWidget {
  final Map<String, dynamic> classData;

  const _AssignmentsButton({required this.classData});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/list-assignment-student',
          arguments: classData,
        );
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.grade, 'Danh sách bài tập/ kiểm tra'),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Logic khi nhấn vào "Điểm danh"
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.check_circle, 'Điểm danh'),
    );
  }
}

class _RequestLeaveButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Logic khi nhấn vào "Xin phép nghỉ học"
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.add_chart_sharp, 'Xin phép nghỉ học'),
    );
  }
}

Widget _getButtonContent(IconData icon, String text) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, color: AppColors.primary, size: 30),
      const SizedBox(height: 8),
      Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        textAlign: TextAlign.center,
      ),
    ],
  );
}

final _buttonStyle = ElevatedButton.styleFrom(
  backgroundColor: Colors.yellow[50],
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 3,
  padding: const EdgeInsets.all(16),
);
