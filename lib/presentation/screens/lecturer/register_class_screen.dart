import 'package:flutter/material.dart';
import '../../../core/config/api_class.dart';
import '../../../core/constants/colors.dart';
import 'dart:convert';
import '../../../core/utils/token.dart';

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


  // Dropdown selections
  String? _classType;
  final List<String> _classTypes = ["LT", "BT", "LT_BT"];

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

      try {
        final response = await ApiClass().post('/create_class', data);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration successful!')),
          );
        } else {
          Map<String, dynamic> responseData = json.decode(response.body);
          String errorMessage = responseData["data"] ?? 'Something went wrong ${responseData["meta"]}';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Registration failed: ${errorMessage}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _getToken() async {
    _token = (await Token().get())!;
  }

  @override
  void initState() {
    super.initState();
    _getToken();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("2024.1"),
        backgroundColor: AppColors.primary, // Use primary color from AppColors
        actions: [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: TextButton(
              onPressed: () {},
              child: Text("Đăng kí lớp học", style: TextStyle(color: AppColors.tertiary)), // Use tertiary color for text
            ),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Class ID Input
              TextFormField(
                controller: _classIdController,
                decoration: InputDecoration(labelText: "Class ID"),
                validator: (value) => value!.isEmpty ? 'Class ID is required' : null,
              ),
              SizedBox(height: 10),

              // Class Name Input
              TextFormField(
                controller: _classNameController,
                decoration: InputDecoration(labelText: "Class Name"),
                validator: (value) => value!.isEmpty ? 'Class Name is required' : null,
              ),
              SizedBox(height: 10),

              // Class Type Dropdown
              DropdownButtonFormField<String>(
                value: _classType,
                decoration: InputDecoration(labelText: "Class Type"),
                items: _classTypes
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) => setState(() => _classType = value),
                validator: (value) => value == null ? 'Please select class type' : null,
              ),
              SizedBox(height: 10),

              // Start Date Input
              TextFormField(
                controller: _startDateController,
                decoration: InputDecoration(labelText: "Start Date (YYYY-MM-DD)"),
                validator: (value) => value!.isEmpty ? 'Start Date is required' : null,
              ),
              SizedBox(height: 10),

              // End Date Input
              TextFormField(
                controller: _endDateController,
                decoration: InputDecoration(labelText: "End Date (YYYY-MM-DD)"),
                validator: (value) => value!.isEmpty ? 'End Date is required' : null,
              ),
              SizedBox(height: 10),

              // Max Student Amount Input
              TextFormField(
                controller: _maxStudentAmountController,
                decoration: InputDecoration(labelText: "Max Student Amount"),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Max Student Amount is required' : null,
              ),
              SizedBox(height: 10),

              SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _submitData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonColor, // Use button color from AppColors
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text("Submit"),
              ),
            ],
          ),
        ),
      ),
    );
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
}
