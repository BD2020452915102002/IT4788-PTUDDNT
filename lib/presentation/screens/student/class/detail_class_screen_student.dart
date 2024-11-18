import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'about_material/list_material.dart';

class DetailClassScreenStudent extends StatelessWidget {
  final Map<dynamic, dynamic> classData;
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
          childAspectRatio: 1,
          children: [
            _ClassInfoButton(),
            _ViewMaterialsButton(classData: classData),
            _AssignmentsButton(classData: classData),
            _AttendanceButton(classData: classData),
            _RequestLeaveButton(classId: classData['class_id']),
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
      child: _getButtonContent(Icons.class_, 'Thông tin lớp học'),
    );
  }
}

class _ViewMaterialsButton extends StatefulWidget {

  final Map<dynamic, dynamic> classData;
  const _ViewMaterialsButton({required this.classData});

  @override
  _ViewMaterialsButtonState createState() => _ViewMaterialsButtonState();
}
class _ViewMaterialsButtonState extends State<_ViewMaterialsButton> {
   late final dynamic classId;
  String token = '';
  @override
  void initState() {
    super.initState();
    classId = widget.classData['class_id'];
    _loadToken();
  }
  Future<void> _loadToken() async {
    setState(() {
      token = Token().get() ?? 'Token not found';
    });
    print("Class ID: ${classId}");
    print("Token: $token");
  }
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Logic khi nhấn vào "Xem tài liệu môn học"
        print("classId: $classId");
        print('token: $token');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ListMaterialScreen(token: token, classId: classId),
          ),
        );

      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.share, 'Xem tài liệu môn học'),
    );
  }
}

class _AssignmentsButton extends StatelessWidget {
  final Map<dynamic, dynamic> classData;

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
  final Map<dynamic, dynamic> classData;

  const _AttendanceButton({required this.classData});
  @override
  Widget build(BuildContext context) {
    final classId = classData['class_id'] as String;

    return ElevatedButton(
      onPressed: () {
        // Logic khi nhấn vào "Điểm danh"
        Navigator.pushNamed(context, '/absent-record-student', arguments: classId);
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.check_circle, 'Điểm danh'),
    );
  }
}

class _RequestLeaveButton extends StatelessWidget {
  final String classId;

  const _RequestLeaveButton({required this.classId});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(
          context,
          '/request-absence',
          arguments: classId,
        );
      },
      style: _buttonStyle,
      child: _getButtonContent(Icons.add_chart_sharp, 'Xin phép nghỉ học'),
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
        Flexible(
          child: Text(
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
