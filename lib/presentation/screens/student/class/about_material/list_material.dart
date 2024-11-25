
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/constants/colors.dart';
import '../../../../../core/utils/hive.dart';
import '../../../../../data/models/material.dart';


class ListMaterialScreen extends StatefulWidget {
  final String token;
  final String classId;

  const ListMaterialScreen({Key? key, required this.token, required this.classId}) : super(key: key);
  @override
  State<ListMaterialScreen> createState() => _ListMaterialScreenState();
}

class _ListMaterialScreenState extends State<ListMaterialScreen>{
  bool isLoading = true;
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
      print('Token: $token');
      print('Class ID: $classId');

      // Body request
      final body = jsonEncode({
        'token': token,
        'class_id': classId,
      });

      // POST request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json', // Chỉ định kiểu nội dung
        },
        body: body, // Truyền body request
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
      print('Token: $token');
      print('Material ID: $materialId');

      // Body request
      final body = jsonEncode({
        'token': token,
        'material_id': materialId,
      });

      // POST request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json', // Chỉ định kiểu nội dung
        },
        body: body, // Truyền body request
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
  Future<void> reloadData() async {
    try {
      // Lấy dữ liệu hiện tại từ Hive
      final currentData = HiveService().getData('tailieu');
      print('Current Hive Data: $currentData');

      // Xóa dữ liệu cũ trong Hive
      await HiveService().saveData('tailieu', null);
      print('Old data removed from Hive.');

      // Tải dữ liệu mới từ API
      await fetchMaterials(widget.token, widget.classId);
      print('New data fetched from API.');

      // Lấy dữ liệu mới từ Hive
      final newData = HiveService().getData('tailieu');
      setState(() {
        materials = (newData as List)
            .map((json) => MaterialClass.fromJson(json))
            .toList();
        isLoading = false;
      });

      print('New data loaded to screen: ${materials.length} items.');
    } catch (e) {
      print('Error in reloadData: $e');
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
      body: RefreshIndicator(
        onRefresh: reloadData, // Gọi hàm reloadData khi kéo xuống
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : materials.isEmpty
            ? Center(child: Text("No material found."))
            : ListView.builder(
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final material = materials[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index == 0) const SizedBox(height: 10.0),
                Card(
                  margin: EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text(material.title),
                    subtitle: Text(material.description),
                    trailing: Text(material.materialType),
                    onTap: () {
                      _showMaterialDetailsDialog(context,
                          material.id.toString(), widget.token);
                    },
                  ),
                ),
              ],
            );
          },
        ),
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

          ],
        );
      },
    );
  }

}