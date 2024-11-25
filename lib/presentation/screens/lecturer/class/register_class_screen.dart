import 'package:flutter/material.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import '../../../../core/config/api_class.dart';
import '../../../../core/constants/colors.dart';
import 'dart:convert';
import '../../../../core/utils/token.dart';

class RegisterClassLecturer extends StatefulWidget {
  const RegisterClassLecturer({super.key});

  @override
  State<RegisterClassLecturer> createState() => _RegisterClassLecturerState();
}

class _RegisterClassLecturerState extends State<RegisterClassLecturer> {
  final _formKey = GlobalKey<FormState>();
  final _classIdController = TextEditingController();
  final _classNameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _maxStudentAmountController = TextEditingController();

  String _token = '';
  String? _classType;
  final List<String> _classTypes = ["LT", "BT", "LT_BT"];

  Future<void> _pickDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      controller.text = "${pickedDate.toLocal()}".split(' ')[0];
    }
  }

  Future<void> _clearFields() async {
    _classIdController.clear();
    _classNameController.clear();
    _startDateController.clear();
    _endDateController.clear();
    _maxStudentAmountController.clear();
    setState(() {
      _classType = null;
    });
  }

  Future<void> _submitData() async {
    if (_formKey.currentState!.validate()) {
      final data = {
        "token": _token,
        "class_id": _classIdController.text,
        "class_name": _classNameController.text,
        "class_type": _classType,
        "start_date": _startDateController.text,
        "end_date": _endDateController.text,
        "max_student_amount": int.tryParse(_maxStudentAmountController.text) ?? 0,
      };

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissal while loading
        builder: (context) => Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      );

      try {
        final response = await ApiClass().post('/create_class', data);
        Navigator.pop(context); // Close the loading dialog

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful!')),
          );
          _clearFields();
        } else {
          showError(response);
        }
      } catch (e) {
        Navigator.pop(context); // Close the loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _logout() async {
    HiveService().clearBox();
    Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
      "/login",
          (Route<dynamic> route) => false,
    );
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

  @override
  void initState() {
    super.initState();
    _getToken();
  }

  Future<void> _getToken() async {
    _token = (await Token().get())!;
  }

  @override
  void dispose() {
    _classIdController.dispose();
    _classNameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _maxStudentAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tạo lớp học", style: TextStyle(
          color: AppColors.tertiary
        )),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(
          color: AppColors.tertiary,
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _classIdController,
                decoration: InputDecoration(
                  labelText: "ID lớp học",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? 'ID lớp học không thể để trống' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _classNameController,
                decoration: InputDecoration(
                  labelText: "Tên lớp học",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value!.isEmpty ? 'Tên lóp học không thể để trống' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _classType,
                decoration: InputDecoration(
                  labelText: "Loại lớp",
                  border: OutlineInputBorder(),
                ),
                items: _classTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _classType = value),
                validator: (value) =>
                value == null ? 'Hãy chọn loại lớp học' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _startDateController,
                decoration: InputDecoration(
                  labelText: "Ngày bắt đầu (YYYY-MM-DD)",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, // Prevent manual text entry
                onTap: () => _pickDate(_startDateController), // Trigger date picker
                validator: (value) => value!.isEmpty ? 'Không thể để trống' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _endDateController,
                decoration: InputDecoration(
                  labelText: "Ngày kết thúc (YYYY-MM-DD)",
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true, // Prevent manual text entry
                onTap: () => _pickDate(_endDateController), // Trigger date picker
                validator: (value) => value!.isEmpty ? 'Không thể để trống' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _maxStudentAmountController,
                decoration: InputDecoration(
                  labelText: "Số lượng sinh viên",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value!.isEmpty ? 'Số lượng sinh viên không thể để trống' : null,
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttonColor,
                      ),
                      child: Text("Tạo lớp"),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFields,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textColor,
                        side: BorderSide(color: AppColors.primary),
                        backgroundColor: AppColors.secondary,
                      ),
                      child: const Text("Xóa toàn bộ"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
