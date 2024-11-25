import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/constants/colors.dart';
//import 'package:image_picker/image_picker.dart';

class CreateMaterialScreen extends StatefulWidget {
  final String token;
  final dynamic classId;

  const CreateMaterialScreen(
      {Key? key, required this.token, required this.classId})
      : super(key: key);

  @override
  _CreateMaterialScreenState createState() => _CreateMaterialScreenState();
}

class _CreateMaterialScreenState extends State<CreateMaterialScreen> {
  String? selectedFileName;
  File? selectedFile;
  String? materialType;
  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
        selectedFileName = result.files.single.name;
        print("File selected: ${selectedFile!.path}");
      });
    }
  }

  Future<void> _uploadMaterial() async {
    if (selectedFile == null ||
        widget.token == null ||
        widget.classId == null) {
      print('token: ${widget.token}');
      print('classId: ${widget.classId}');
      print('selectedFile: $selectedFile');
      print("Token, classId, or file is missing");
      return;
    }
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://157.66.24.126:8080/it5023e/upload_material'));
    request.fields['token'] = widget.token;
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['classId'] = widget.classId;
    request.fields['materialType'] = materialType!;

    request.files
        .add(await http.MultipartFile.fromPath('file', selectedFile!.path));

    final response = await request.send();
    final responseString = await response.stream.bytesToString();
    final responseData = jsonDecode(responseString);

    if (response.statusCode == 201) {
      print("Material created successfully");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Material created successfully!")));
      Navigator.pop(context, true);
      // Navigator.pop(context, true);
    } else {
      print("Failed to create Material");
      print("Response body: $responseString");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text("Failed to create Material: ${responseData['message']}")));
      print("Failed to create Material: ${responseData['message']}");
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
          "Tạo tài liệu tham khảo",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: SingleChildScrollView(
        // Thêm SingleChildScrollView ở đây
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Title:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextFormField(
                  controller: titleController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Giảm bo góc
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Giảm bo góc
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Material Type:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                DropdownButtonFormField<String>(
                  value: materialType,
                  items: ['PNG', 'PDF', 'DOC']
                      .map((type) =>
                          DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      materialType = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a material type';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10), // Giảm bo góc
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC02135),
                          padding: EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 5,
                        ),
                        onPressed: pickFile,
                        child: Text(selectedFile != null
                            ? "File Selected"
                            : "Pick File"),
                      ),
                      if (selectedFileName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'File đã chọn: $selectedFileName',
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFC02135),
                      padding:
                          EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 5,
                    ),
                    onPressed: _uploadMaterial,
                    child: Text("Upload Material"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
