import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:intl/intl.dart';
import 'package:ptuddnt/core/utils/token.dart';


class LeaveRequestScreen extends StatefulWidget {
  final String classId;

  const LeaveRequestScreen({super.key, required this.classId});

  @override
  LeaveRequestScreenState createState() => LeaveRequestScreenState();
}

class LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  File? _selectedFile;
  final _picker = ImagePicker();
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  late final String token ;

  @override
  void initState() {
    super.initState();
    token = Token().get();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _dateController.dispose();
    super.dispose();
  }

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
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  void _showCustomSnackBar(String message, BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 80.0,
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

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  bool _isFormValid() {
    return _selectedDate != null && _reasonController.text.isNotEmpty;
  }

  Future<void> _submitAbsenceRequest() async {
    if (_isSubmitting || !_isFormValid()) {
      _showCustomSnackBar('Vui lòng điền đầy đủ thông tin', context);
      return;
    }
    if (_selectedFile == null || _selectedDate == null) {
      _showCustomSnackBar('Vui lòng chọn tệp và ngày xin nghỉ', context);
      return;
    }
    if (token == '') {
      _showCustomSnackBar('Token không hợp lệ', context);
      return;
    }
    setState(() {
      _isSubmitting = true;
    });

    final url = Uri.parse('http://157.66.24.126:8080/it5023e/request_absence');

    final request = http.MultipartRequest('POST', url)
      ..fields['token'] = token
      ..fields['classId'] = widget.classId
      ..fields['reason'] = _reasonController.text
      ..fields['date'] = _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : ''
      ..fields['title'] = _titleController.text;

    if (_selectedFile != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _selectedFile!.path,
        filename: path.basename(_selectedFile!.path),
      ));
    }
    final response = await request.send();
    setState(() {
      _isSubmitting = false;
    });

    if (response.statusCode == 200) {
      _showCustomSnackBar('Gửi yêu cầu thành công', context);
    } else {
      final responseBody = await response.stream.bytesToString();
      _showCustomSnackBar('Gửi yêu cầu thất bại: $responseBody', context);
    }
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
                  const SizedBox(height: 8),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Title",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    onChanged: (value) {
                    },
                    decoration: InputDecoration(
                      hintText: "Nhập tiêu đề",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: AppColors.primary,
                          width: 2.0,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Lý do",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildTextField(
                    _reasonController,
                    maxLines: 4,
                    hintText: "Nhập lý do",
                    hintStyle: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),


                  const SizedBox(height: 16),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(100, 50),
                      maximumSize: const Size(160, 50),
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: _pickFile,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _selectedFile == null
                                ? "Nộp minh chứng"
                                : "File đã chọn: ${path.basename(_selectedFile!.path)}",
                            style: const TextStyle(color: Colors.white, fontStyle: FontStyle.italic),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Ngày xin nghỉ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: _buildTextField(_dateController),
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
                onPressed: _isSubmitting ? null : _submitAbsenceRequest,
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : const Text("Xác nhận", style: TextStyle(fontSize: 18)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    {
      int maxLines = 1,
      String? hintText,
      TextStyle? hintStyle
    }
  ){
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: hintStyle,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
      ),
    );
  }
}
