import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/presentation/screens/common/home_screen.dart';

class ClassInfo extends StatefulWidget {
  final String classId;

  const ClassInfo({super.key, required this.classId});

  @override
  State<ClassInfo> createState() => _ClassInfoState();
}

class _ClassInfoState extends State<ClassInfo> {
  Map<dynamic, dynamic>? classData;
  bool isLoading = false;
  bool isLoadingBtn1 = false;
  bool isLoadingBtn2 = false;
  bool isLoadingBtn3 = false;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final classDataCache = HiveService().getData(widget.classId);
    if (classDataCache == null) {
      setState(() {
        isLoading = true;
      });
      await fetchClassInfo();
    }
    setState(() {
      classData = HiveService().getData(widget.classId);
      isLoading = false;
    });
  }

  Future<void> fetchClassInfo() async {
    print('vao day');
    try {
      final res = await ApiClass().post('/get_class_info', {
        "token": Token().get(),
        "role": HiveService().getData('userData')['role'],
        "class_id": widget.classId
      });
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        await HiveService().saveData(widget.classId, data['data']);
      }
    } catch (e) {}
  }

  Future<void> addStudent(String id) async {
    setState(() {
      isLoadingBtn1 = true;
    });

    try {
      final res = await ApiClass().post('/add_student', {
        "token": Token().get(),
        "account_id": id,
        "class_id": widget.classId,
      });

      if (res.statusCode == 200) {
        await fetchClassInfo();
        setState(() {
          classData = HiveService().getData(widget.classId);
          isLoadingBtn1 = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thêm sinh viên thành công')),
        );
      } else {
        setState(() {
          isLoadingBtn1 = false; // Kết thúc trạng thái loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${res.body}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingBtn1 = false; // Kết thúc trạng thái loading
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi. Vui lòng thử lại sau.')),
      );
    }
  }

  void _addStudent() {
    TextEditingController idController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Center(
                child: Text(
                  'Thêm Sinh Viên',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nhập ID của sinh viên:'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: idController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: const BorderSide(color: Colors.white60),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    String id = idController.text.trim();
                    if (id.isNotEmpty) {
                      setState(() {
                        isLoadingBtn1 = true; // Bắt đầu loading trong dialog
                      });
                      await addStudent(id);
                      Navigator.pop(context); // Đóng dialog sau khi xử lý xong
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Vui lòng nhập ID')),
                      );
                    }
                  },
                  child: isLoadingBtn1
                      ? SizedBox(
                          width: 60, // Đặt chiều rộng cố định cho nút
                          height: 20, // Đặt chiều cao cố định cho nút
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const Text('Thêm'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _editClassInfo() {
    TextEditingController classNameController = TextEditingController();
    String selectedStatus = "ACTIVE"; // Giá trị mặc định
    DateTime? selectedStartDate;
    DateTime? selectedEndDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Center(
                  child: const Text(
                'Thay Đổi Thông Tin Lớp',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              )),
              content: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(0),
                  // Thêm khoảng cách bên ngoài
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Căn lề trái cho nội dung
                    children: [
                      const Text(
                        'Nhập tên lớp:',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: classNameController,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            // Làm mềm góc
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: AppColors.primary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        // Căn chỉnh chiều dọc
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Trạng Thái:',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Column(
                                  children: ["ACTIVE", "COMPLETED", "UPCOMING"]
                                      .map(
                                        (status) => Row(
                                          children: [
                                            Radio<String>(
                                              value: status,
                                              groupValue: selectedStatus,
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedStatus = value!;
                                                });
                                              },
                                            ),
                                            Flexible(
                                              child: Text(
                                                status,
                                                style: const TextStyle(
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Cột Ngày
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ngày Bắt Đầu:',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    selectedStartDate == null
                                        ? 'Chọn Ngày'
                                        : '${selectedStartDate!.toLocal()}'
                                            .split(' ')[0],
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    textStyle: const TextStyle(fontSize: 12),
                                    backgroundColor: Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        selectedStartDate = pickedDate;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Ngày Kết Thúc:',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.date_range),
                                  label: Text(
                                    selectedEndDate == null
                                        ? 'Chọn Ngày'
                                        : '${selectedEndDate!.toLocal()}'
                                            .split(' ')[0],
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 16),
                                    textStyle: const TextStyle(fontSize: 12),
                                    backgroundColor: Colors.grey[200],
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (pickedDate != null) {
                                      setState(() {
                                        selectedEndDate = pickedDate;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Gọi hàm cập nhật thông tin lớp
                    await editClassInfofuns(
                      className: classNameController.text.trim(),
                      status: selectedStatus,
                      startDate: selectedStartDate,
                      endDate: selectedEndDate,
                    );
                    Navigator.pop(context); // Đóng dialog sau khi cập nhật
                  },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Hàm sửa thông tin lớp (thêm tham số đầu vào)
  Future<void> editClassInfofuns({
    required String className,
    required String status,
    required DateTime? startDate,
    required DateTime? endDate,
  }) async {
    setState(() {
      isLoadingBtn2 = true;
    });
    try {
      final res = await ApiClass().post('/edit_class', {
        "token": Token().get(),
        "class_id": widget.classId,
        "class_name": className,
        "status": status, // ACTIVE, COMPLETED, UPCOMING
        "start_date": startDate?.toIso8601String(),
        "end_date": endDate?.toIso8601String()
      });

      if (res.statusCode == 200) {
        await fetchClassInfo();
        setState(() {
          classData = HiveService().getData(widget.classId);
          isLoadingBtn2 = false; // Kết thúc trạng thái loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      } else {
        setState(() {
          isLoadingBtn2 = false; // Kết thúc trạng thái loading
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${res.body}')),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingBtn2 = false; // Kết thúc trạng thái loading
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi. Vui lòng thử lại sau.')),
      );
    }
  }

  Future<void> deleteClass() async {
    setState(() {
      isLoadingBtn3 = true;
    });
    try {
      final res = await ApiClass().post('/delete_class', {
        "token": Token().get(),
        "class_id": widget.classId,
        "role": HiveService().getData('userData')['role'],
      });
      if (res.statusCode == 200) {
        await HiveService().deleteData(widget.classId);
        await HiveService().deleteData('classList');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa thành công')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xảy ra lỗi. Vui lòng thử lại sau.')),
      );
    }
  }

  void _deleteClass() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xóa Lớp Học'),
          content: const Text('Bạn có chắc chắn muốn xóa lớp học này không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteClass();
                Navigator.pop(context);
              },
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            '${classData?['class_name'] ?? 'Lớp học'}',
            style: const TextStyle(color: Colors.white),
          ),
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
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mã lớp: ${classData!['class_id']}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text('Loại lớp: ${classData!['class_type']}'),
                    Text('Giảng viên: ${classData!['lecturer_name']}'),
                    Text('Số lượng sinh viên: ${classData!['student_count']}'),
                    Text(
                        'Thời gian: ${classData!['start_date']} - ${classData!['end_date']}'),
                    Text('Trạng thái: ${classData!['status']}'),
                    const SizedBox(height: 20),
                    const Text(
                      'Danh sách sinh viên:',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    classData!['student_accounts'].isEmpty
                        ? Text('Không có sinh viên trong lớp học')
                        : Expanded(
                            child: ListView.builder(
                              itemCount: classData!['student_accounts'].length,
                              itemBuilder: (context, index) {
                                final student =
                                    classData!['student_accounts'][index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: ListTile(
                                    title: Text(
                                        '${student['first_name']} ${student['last_name']}'),
                                    subtitle: Text(student['email']),
                                    trailing:
                                        Text('ID: ${student['student_id']}'),
                                  ),
                                );
                              },
                            ),
                          ),
                  ],
                ),
              ),
        bottomNavigationBar:
            HiveService().getData('userData')['role'] == 'LECTURER'
                ? BottomNavigationBar(
                    selectedItemColor: Colors.red,
                    unselectedItemColor: Colors.red,
                    type: BottomNavigationBarType.fixed,
                    // Đảm bảo tất cả mục có cùng kích thước
                    items: const [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.person_add),
                        label: 'Thêm SV',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.edit),
                        label: 'Sửa Lớp',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.delete),
                        label: 'Xóa Lớp',
                      ),
                    ],
                    onTap: (index) {
                      if (index == 0) _addStudent();
                      if (index == 1) _editClassInfo();
                      if (index == 2) _deleteClass();
                    },
                  )
                : null);
  }
}
