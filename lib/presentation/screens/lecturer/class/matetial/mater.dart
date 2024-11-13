
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../data/models/material.dart';

class MaterialScreen extends StatefulWidget {
  final String token;
  final String classId;

const MaterialScreen({Key? key, required this.token, required this.classId}) : super(key: key);
  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen>{
  bool isLoading = true;
  List<MaterialClass> materials = [];

  @override
  void initState() {
    super.initState();
    loadMater();
  }
  Future<void> loadMater() async {
    materials = await fetchMaterials(widget.token, widget.classId );

    setState(() {
      isLoading = false;
    });
  }
  Future<List<MaterialClass>> fetchMaterials(String token, String classId) async {
  try{
    final uri = Uri.parse('http://160.30.168.228:8080/it5023e/get_material_list').replace(
        queryParameters: {
          'token': widget.token,
          'class_id': widget.classId,
        },
    );
    final response = await http.get(uri);
    print('Token: ${widget.token}');
    print('Class ID: ${widget.classId}');

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      if (jsonResponse != null && jsonResponse['data'] != null) {
        final data = jsonResponse['data'] as List;
        return data.map((json) => MaterialClass.fromJson(json)).toList();
      }
    } else {
      throw Exception('Lỗi khi lấy dữ liệu: ${response.statusCode}');
    }
  }catch(e){
    print('Đã xảy ra lỗi: $e');
  }
  return [];
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
    }
  }
  Future<MaterialClass> fetchMaterialDetails(String materialId, String token) async {
    try {

      final uri = Uri.parse(
          'http://160.30.168.228:8080/it5023e/get_material_info')
          .replace(queryParameters: {
        'token': widget.token,
        'material_id': materialId ,
      });
      print('Token: ${widget.token}');
      print('Material ID: ${materialId}');

      final response = await http.get(
        uri,
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final data = jsonResponse['data'];
        print('Decoded data: $data');
        return MaterialClass.fromJson(data);

        // final data = jsonDecode(response.body);
        // print('Decoded data: $data');
        // return MaterialClass.fromJson(data);
      } else {
        throw Exception(
            'Failed to load material details ${response.statusCode}');
      }
    } catch (e) {
      print('Đã xảy ra lỗi: $e');
      return MaterialClass(
        id: 0,
        title: 'Unknown',
        description: 'Unknown',
        materialType: 'Unknown',
        materialLink: '',
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
          "Tài liệu tham khảo",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : materials.isEmpty
          ? Center(child: Text("No material found."))
          : Stack(
          children: [
            ListView.builder(
              itemCount: materials.length,
              itemBuilder: (context, index) {
                final material = materials[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (index == 0) const SizedBox(height: 10.0),
                    Card(
                      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        title: Text(material.title),
                        subtitle: Text(material.description),
                        trailing: Text(material.materialType),
                        onTap: () {
                          _showMaterialDetailsDialog(context, material.id.toString(), widget.token);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              bottom: 50.0,
              right: 20.0,
              child: FloatingActionButton(
                onPressed: () async {
                  // Thêm code để mở màn hình thêm material
                },
                child: Icon(Icons.add),
              ),
            ),
          ],
        ),

    );
  }
  void _showMaterialDetailsDialog(BuildContext context, String materialId, String token ) async {
    // Giả sử đây là hàm để lấy dữ liệu chi tiết của material bằng materialId
    final materialDetails = await fetchMaterialDetails(materialId, token);
    print('Material details: $materialDetails');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(materialDetails.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Description: ${materialDetails.description}"),
              Text("Type: ${materialDetails.materialType}"),
              GestureDetector(
                onTap: () {
                  if (materialDetails.materialLink.isNotEmpty) {
                    _launchURL(materialDetails.materialLink);
                  }
                },
                child: Text(
                  "${materialDetails.materialLink.isNotEmpty ? materialDetails.materialLink : 'N/A'}",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

}