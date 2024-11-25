
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../data/models/material.dart';
import 'create_material.dart';
import 'edit_material.dart';

class MaterialScreen extends StatefulWidget {
  final String token;
  final String classId;

const MaterialScreen({Key? key, required this.token, required this.classId}) : super(key: key);
  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen>{
  bool isLoading = false;
  bool isReloading = false;
  List<MaterialClass> materials = [];

  @override
  void initState() {
    super.initState();
    _init();
  }
  Future<void> _init () async {
    final tl = HiveService().getData('tailieu');
    if ( tl == null ){
      await loadMater();
    }
    setState(() {
      materials = (HiveService().getData('tailieu') as List).map((json) => MaterialClass.fromJson(json)).toList();
      isLoading = false;
    });
  }
  Future<void> loadMater() async {
     await fetchMaterials(widget.token, widget.classId );
  }
  Future<void> fetchMaterials(String token, String classId) async {
    setState(() {
      isLoading = true;
    });
    try {
      final uri = Uri.parse('http://157.66.24.126:8080/it5023e/get_material_list');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': widget.token,
          'class_id': widget.classId,
        }),
      );

      print('Token: ${widget.token}');
      print('Class ID: ${widget.classId}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse != null && jsonResponse['data'] != null) {
          await HiveService().saveData('tailieu', jsonResponse['data']);
        }
      } else {
        throw Exception('Lỗi khi lấy dữ liệu: ${response.statusCode}');
      }
    } catch (e) {
      print('Đã xảy ra lỗi: $e');
    }
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
      final uri = Uri.parse('http://157.66.24.126:8080/it5023e/get_material_info');

      print('Token: ${widget.token}');
      print('Material ID: $materialId');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': widget.token,
          'material_id': materialId,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        final data = jsonResponse['data'];
        print('Decoded data: $data');
        return MaterialClass.fromJson(data);
      } else {
        throw Exception(
            'Failed to load material details: ${response.statusCode}');
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
  Future<void> _deleteMaterial(String id) async {
    print('Xóa Material: $id');
    print('Token: $widget.token');
    try {
      var response = await http.post(
        Uri.parse('http://157.66.24.126:8080/it5023e/delete_material'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "token": widget.token,  // Thay bằng token thực tế
          "material_id": id,
        }),
      );
      if (response.statusCode == 200) {
        print('Xóa material thành công');
        setState(() {
          // Xóa bài viết khỏi danh sách của bạn
          loadMater();
        });
      } else {
        print('Lỗi xóa material: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi xóa materal  : $e');
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
      body: Stack(
        children: [
          if (isLoading)
            Center(child: CircularProgressIndicator())
          else if (materials.isEmpty)
            Center(child: Text("No material found."))
          else
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
                          _showMaterialDetailsDialog(
                              context, material.id.toString(), widget.token);
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
                print('Token press: ${widget.token}');
                print('Class ID press create: ${widget.classId}');
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateMaterialScreen(
                      token: widget.token,
                      classId: widget.classId,
                    ),
                  ),
                );
                if (result == true) {
                  setState(() {
                    isReloading = true; // Set trạng thái reload
                    loadMater();
                  });
                }
              },
              child: Icon(Icons.add),
              backgroundColor: Color(0xFFC02135),
              foregroundColor: Color(0xFFF2C209),
            ),
          ),
        ],
      ),
    );
  }

  void _showMaterialDetailsDialog(BuildContext context, String materialId, String token ) async {
    final materialDetails = await fetchMaterialDetails(materialId, token);
    print('Material details: $materialDetails');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Container(
            padding: EdgeInsets.all(10),
            color: Color(0xFFC02135), // Đặt màu nền đỏ//
            child: Center(
              child: Text(
                materialDetails.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Description: ${materialDetails.description}"),
              const SizedBox(height: 10),
              Text("Type: ${materialDetails.materialType}"),
              const SizedBox(height: 10),
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
              child: Text("Đóng"),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            TextButton(
              onPressed: () {
                // Call API to delete assignment
                _deleteMaterial(materialId.toString());
                Navigator.pop(context);
              },
              child: Text('Xóa'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Xác nhận'),
                      content: Text('Bạn phải cập nhật lại file nếu muốn tiếp tục sửa.'),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Đóng dialog
                          },
                          child: Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Đóng dialog trước khi chuyển trang
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditMaterialScreen(
                                  token: widget.token,
                                  materialId: materialId,
                                ),
                              ),
                            ).then((result) {
                              if (result == true) {
                                setState(() {
                                  isReloading = true; // Set trạng thái reload
                                  loadMater();
                                });
                              }
                            });
                          },
                          child: Text('Đồng ý'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Text('Edit'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),

          ],
        );
      },
    );
  }

}