import 'package:flutter/material.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/presentation/screens/lecturer/class/assignment/assignment.dart';
import 'matetial/mater.dart';

class DetailClassScreenLec extends StatefulWidget {
    final Map<String, dynamic> classData;
    const DetailClassScreenLec({super.key, required this.classData});

    @override
    State<DetailClassScreenLec> createState() => _DetailClassScreenLecState();
}
class _DetailClassScreenLecState extends State<DetailClassScreenLec> {
    late String token = '';
    late final dynamic classId;

    @override
    void initState() {
      super.initState();
      classId = widget.classData['class_id'] ?? 'Unknown';
      _loadToken();
    }
    Future<void> _loadToken() async {
      setState(() {
        token = Token().get() ?? 'Token not found';
      });
      print("Class ID: ${classId}");
      print("Token: $token");
    }

    Widget _getButtonContent(int index) {
    List<Map<String, dynamic>> buttonData = [
      {
        'icon': Icons.people,
        'text': 'Danh sách sinh viên',
      },
      {
        'icon': Icons.share,
        'text': 'Tài liệu chia sẻ',
      },
      {
        'icon': Icons.grade,
        'text': 'Nhập điểm',
      },
      {
        'icon': Icons.check_circle,
        'text': 'Điểm danh',
      },
      {
        'icon': Icons.assignment,
        'text': 'Tạo bài tập / khảo sát',
      },
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          buttonData[index]['icon'],
          color: AppColors.primary,
          size: 30,
        ),
        const SizedBox(width: 8),
        Text(
          buttonData[index]['text'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  void _handleButtonPress(BuildContext context, int index) {
    switch (index) {
      case 0:
        print("Danh sách sinh viên pressed");
        break;
      case 1:
        print("Tài liệu chia sẻ pressed");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialScreen(token: token, classId: classId),
          ),
        );
        break;
      case 2:
        print("Nhập điểm pressed");
        break;
      case 3:
        print("Điểm danh pressed");
        break;
      case 4:
        print("Tạo bài tập / khảo sát pressed");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AssignmentPage(token: token, classId: classId),
          ),
        );
        break;
    }
  }

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
          widget.classData['class_name'],
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 1,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 20.0,
            childAspectRatio: 4,
          ),
          itemCount: 5,
          itemBuilder: (context, index) {
            return ElevatedButton(
              onPressed: () => _handleButtonPress(context, index),
              style: ElevatedButton.styleFrom(

                backgroundColor: Colors.yellow[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              ),
              child: _getButtonContent(index),
            );
          },
        ),
      ),
    );
  }
}
