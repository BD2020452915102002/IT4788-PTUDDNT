import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/presentation/screens/lecturer/class/assignment/assignment.dart';
import 'matetial/mater.dart';

class DetailClassScreenLec extends StatelessWidget {
  final Map<dynamic, dynamic> classData;

  const DetailClassScreenLec({super.key, required this.classData});

  @override
  Widget build(BuildContext context) {
    String token = Token().get();

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
          childAspectRatio: 1,
          children: [
            _ClassInfoButton(),
            _ViewMaterialsButton(classData: classData, token: token),
            _GradeButton(classData: classData, token: token),
            _AttendanceButton(),
            _CreateAssignmentButton(classData: classData, token: token),
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
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.class_, 'Thông tin lớp dạy'),
    );
  }
}

class _ViewMaterialsButton extends StatelessWidget {
  final Map<dynamic, dynamic> classData;
  final String token;

  const _ViewMaterialsButton({required this.classData, required this.token});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialScreen(token: token, classId: classData['class_id']),
          ),
        );
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.share, 'Tài liệu chia sẻ'),
    );
  }
}

class _GradeButton extends StatelessWidget {
  final Map<dynamic, dynamic> classData;
  final String token;

  const _GradeButton({required this.classData, required this.token});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.grade, 'Nhập điểm'),
    );
  }
}

class _AttendanceButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.check_circle, 'Điểm danh'),
    );
  }
}

class _CreateAssignmentButton extends StatelessWidget {
  final Map<dynamic, dynamic> classData;
  final String token;

  const _CreateAssignmentButton({required this.classData, required this.token});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssignmentScreen(token: token, classId: classData['class_id']),
          ),
        );
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.assignment, 'Tạo bài tập / khảo sát'),
    );
  }
}

Widget _getButtonContent(IconData icon, String text) {
  return Expanded(
    child: Column(
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
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
