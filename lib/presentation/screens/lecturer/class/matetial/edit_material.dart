import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/constants/colors.dart';
import 'package:image_picker/image_picker.dart';

class EditMaterialScreen extends StatefulWidget {
  final String token;
  final String materialId;
  const EditMaterialScreen({Key? key, required this.token, required this.materialId}) : super(key: key);
  @override
  _EditMaterialScreenState createState() => _EditMaterialScreenState();
}
class _EditMaterialScreenState extends State<EditMaterialScreen> {

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();
  TextEditingController materialTypeController = TextEditingController();
  String? filePath;
  @override
  void initState() {
    super.initState();
    fetchMaterialDetails();
  }
  Future<void> fetchMaterialDetails() async {
    try{
      final uri = Uri.parse('http://160.30.168.228:8080/it5023e/get_material_info').replace(
        queryParameters: {
          'token': widget.token,
          'material_id': widget.materialId,
        },
      );
      final response = await http.get(uri);
      print('Token: ${widget.token}');
      print('material_id: ${widget.materialId}');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final data = responseData['data'];

        titleController.text = data['material_name'] ?? 'Unknown title';
        descriptionController.text = data['description'] ?? 'No description';
        materialTypeController.text = data['material_type'] ?? 'No type';

        filePath = data['material_link'];
      } else {
        throw Exception('Lỗi khi lấy dữ liệu: ${response.statusCode}');
      }
    }catch(e){
      print('Đã xảy ra lỗi: $e');
    }
  }
  Future<void> saveChanges() async {

    var request = http.MultipartRequest('POST', Uri.parse('http://160.30.168.228:8080/it5023e/edit_material'));
    request.fields['materialId'] = widget.materialId.toString();
    request.fields['title'] = titleController.text;
    request.fields['description'] = descriptionController.text;
    request.fields['materialType'] = materialTypeController.text;
    request.fields['token'] = widget.token;

    if (filePath != null) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath!));
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      // Handle success
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved successfully')));
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save changes')));
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Material"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 15,),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 15,),
            TextField(
              controller: materialTypeController,
              decoration: InputDecoration(labelText: 'Material Type'),
            ),
            SizedBox(height: 15,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC02135),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              onPressed: () async {
                // Code to pick file and set filePath
              },
              child: Text(filePath == null ? 'Choose File' : 'File Selected'),
            ),
            SizedBox(height: 20,),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFC02135),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 5,
              ),
              onPressed: saveChanges,
              child: Text('Save', style: TextStyle(fontWeight: FontWeight.bold, )),
            ),
          ],
        ),
      ),
    );
  }

}