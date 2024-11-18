import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:intl/intl.dart';

class LeaveRequestScreen extends StatefulWidget {
  final Map<dynamic, dynamic> classData;

  const LeaveRequestScreen({super.key, required this.classData});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final TextEditingController _reasonController = TextEditingController();
  File? _selectedFile;
  final _picker = ImagePicker();
  DateTime? _selectedDate;

  Future<void> _pickFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showCustomSnackBar(String message, BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80.0, // Khoảng cách từ trên xuống
        left: 0.0,
        right: 0.0,
        child: Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 16.0),
              ),
            ),
          ),
        ),
      ),
    );

    // Thêm OverlayEntry vào màn hình
    overlay.insert(overlayEntry);

    // Ẩn thông báo sau 3 giây
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  Future<void> _submitAbsenceRequest() async {
    final url = Uri.parse('http://160.30.168.228:8080/it5023e/request_absence');

    final request = http.MultipartRequest('POST', url)
      ..fields['token'] = 'RiTn0v'
      ..fields['classId'] = '000002'
      ..fields['date'] = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : ''
      ..fields['reason'] = _reasonController.text;

    if (_selectedFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path,
        filename: path.basename(_selectedFile!.path),
      ));
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      _showCustomSnackBar('Gửi yêu cầu thành công', context);
    } else {
      _showCustomSnackBar('Gửi yêu cầu thất bại', context);
    }
  }


  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.tertiary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Xin phép nghỉ học",
          style: TextStyle(
              color: AppColors.tertiary,
              fontStyle: FontStyle.normal,
              fontFamily: "Roboto"
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Đơn xin nghỉ",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: _buildTextField(
                        "Ngày xin nghỉ",
                        TextEditingController(
                          text: _selectedDate != null
                              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
                              : "",
                        ),
                      ),
                    ),
                  ),
                  _buildTextField("Lý do", _reasonController, maxLines: 3),

                  // Add file picker button here
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 50),
                      maximumSize: const Size(160, 50),
                      backgroundColor: AppColors.subColorSecondary,
                    ),
                    onPressed: _pickFile,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.attach_file,
                          color: Colors.black, // Đặt màu icon thành đen
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _selectedFile == null ? "Minh chứng" : "File đã chọn: ${path.basename(_selectedFile!.path)}",
                          style: const TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 50),
                ),
                onPressed: _submitAbsenceRequest,
                child: const Text("Xác nhận", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
