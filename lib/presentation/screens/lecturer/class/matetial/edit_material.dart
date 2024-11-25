import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

import '../../../../../core/constants/colors.dart';

class EditMaterialScreen extends StatefulWidget {
  final String token;
  final String materialId;

  const EditMaterialScreen({
    Key? key,
    required this.token,
    required this.materialId,
  }) : super(key: key);

  @override
  _EditMaterialScreenState createState() => _EditMaterialScreenState();
}

class _EditMaterialScreenState extends State<EditMaterialScreen> {
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController materialTypeController = TextEditingController();
  File? selectedFile;

  @override
  void initState() {
    super.initState();
    fetchMaterialDetails();
  }

  Future<void> fetchMaterialDetails() async {
    try {
      final uri = Uri.parse(
        'http://157.66.24.126:8080/it5023e/get_material_info',
      );

      // Tạo body request
      final requestBody = {
        'token': widget.token,
        'material_id': widget.materialId,
      };

      // Gửi yêu cầu POST
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Parse dữ liệu JSON
        final responseData = jsonDecode(response.body);
        final data = responseData['data'];

        // Gán dữ liệu vào các controller
        titleController.text = data['material_name'] ?? 'Unknown title';
        descriptionController.text = data['description'] ?? 'No description';
        materialTypeController.text = data['material_type'] ?? 'No type';

        print('Type_get: ${materialTypeController.text}');
      } else {
        // Xử lý khi trạng thái HTTP không thành công
        throw Exception('Lỗi khi lấy dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      // Bắt lỗi và in ra
      print('Đã xảy ra lỗi: $e');
    }
  }

  Future<void> selectFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> saveChanges() async {
    if (selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng chọn file trước khi lưu')),
      );

      return;
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://157.66.24.126:8080/it5023e/edit_material'),
    );
    request.fields['materialId'] = widget.materialId.toString();
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['materialType'] = materialTypeController.text;
    request.fields['token'] = widget.token;
    print('Tpy: ${materialTypeController.text}');
    // Gửi file đã chọn
    request.files.add(
      await http.MultipartFile.fromPath('file', selectedFile!.path),
    );

    final response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu thành công')),
      );
      Navigator.pop(context, true);
      Navigator.pop(context, true);
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lưu thất bại: ${response.statusCode}')),
      );
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
          "Edit Material",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            // Căn chỉnh tiêu đề sang trái
            children: [
              // Title Section
              const Text(
                'Title',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), // Giảm bo góc
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Description Section
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              TextField(
                controller: descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), // Giảm bo góc
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Material Type Section
              const Text(
                'Material Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 5),
              DropdownButtonFormField<String>(
                value:
                    ['PNG', 'PDF', 'DOC'].contains(materialTypeController.text)
                        ? materialTypeController.text
                        : null, // Đặt giá trị mặc định nếu không hợp lệ
                items: ['PNG', 'PDF', 'DOC']
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    materialTypeController.text = value ?? '';
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), // Giảm bo góc
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Buttons Section
              Center(
                child: Column(
                  children: [
                    // Choose File Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC02135),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      onPressed: selectFile,
                      child: Text(
                        selectedFile == null
                            ? 'Choose File'
                            : 'File: ${selectedFile!.path.split('/').last}',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Save Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC02135),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 5,
                      ),
                      onPressed: saveChanges,
                      child: const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
