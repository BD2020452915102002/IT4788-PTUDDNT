import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/constants/colors.dart';

class AssignmentDetailScreen extends StatefulWidget {
  final Map<dynamic, dynamic> assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  @override
  State<AssignmentDetailScreen> createState() => _AssignmentDetailScreenState();
}

class _AssignmentDetailScreenState extends State<AssignmentDetailScreen> {
  String? textResponse;
  File? selectedFile;
  bool loading = false;

  // late final Map<dynamic, dynamic> submitData;
  late String stateAssignment;
  bool loadingSubmit = false;
  Map<dynamic, dynamic> submitData = {};

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    final now = DateTime.now();
    final status = DateTime.parse(widget.assignment['deadline']).isBefore(now);
    if (widget.assignment['is_submitted']) {
      setState(() {
        stateAssignment = 'hoanthanh';
      });
    } else {
      setState(() {
        stateAssignment = status ? 'hethan' : 'chuahoanthanh';
      });
    }

    if (stateAssignment == 'hoanthanh') {
      final cachedData = HiveService().getData('submitData${widget.assignment['id']}');
      if (cachedData == null) {
        await fetchSubmit();
      }
      setState(() {
        submitData = HiveService().getData('submitData${widget.assignment['id']}') ?? {};
      });
    }
  }


  String formatDeadline(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    return DateFormat('dd-MM-yyyy, HH:mm').format(deadlineDate);
  }

  Future<void> fetchSubmit() async {
    if (stateAssignment == 'hoanthanh') {
      try {
        final res = await ApiClass().post('/get_submission',
            {"token": Token().get(), "assignment_id": widget.assignment['id']});
        if (res.statusCode == 200) {
          final data = jsonDecode(utf8.decode(res.bodyBytes));
          await HiveService().saveData('submitData${widget.assignment['id']}', data['data']);
        }
      } catch (err) {}
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

  Future<void> _pickFile() async {
   if(stateAssignment != 'hoanthanh'){
     final result = await FilePicker.platform.pickFiles();
     if (result != null) {
       setState(() {
         selectedFile = File(result.files.single.path!);
       });
     }
   }
  }

  Future<void> _submitAssignment() async {
    // Hiển thị popup nộp bài
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.red,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 10),
              Text("Đang nộp bài..."),
            ],
          ),
        );
      },
    );

    if (selectedFile != null && textResponse != null) {
      final token = Token().get();
      final assignmentID = widget.assignment['id'].toString();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://157.66.24.126:8080/it5023e/submit_survey?file"),
      );
      request.fields['token'] = token;
      request.fields['assignmentId'] = assignmentID;
      request.fields['textResponse'] = textResponse ?? '';
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          selectedFile!.path,
        ),
      );

      try {
        var response = await request.send();
        Navigator.pop(context); // Đóng popup nộp bài
        if (response.statusCode == 200) {
          // Hiển thị popup nộp bài thành công
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Thành công"),
                content: Text("Bài tập đã được nộp thành công!"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, "a");
                      // Đóng popup
                    },
                    child: Text("Đóng"),
                  ),
                ],
              );
            },
          );
        } else {
          // Xử lý lỗi và thông báo
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text("Lỗi"),
                content: Text("Lỗi khi nộp bài tập: ${response.statusCode}"),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Đóng"),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Lỗi kết nối"),
              content: Text("Không thể kết nối tới máy chủ: $e"),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Đóng popup
                  },
                  child: Text("Đóng"),
                ),
              ],
            );
          },
        );
      }
    } else {
      Navigator.pop(context); // Đóng popup nộp bài
      // Hiển thị thông báo lỗi
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Lỗi"),
            content: Text("Vui lòng chọn file và nhập mô tả!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Đóng popup
                },
                child: Text("Đóng"),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_sharp,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Chi tiết bài tập",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  widget.assignment['title'],
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 8),

              Center(
                child: Text(
                  submitData.isNotEmpty && submitData['submission_time'] != null
                      ? 'Nộp bài lúc: ${formatDeadline(submitData['submission_time'])}'
                      : 'Hạn: ${formatDeadline(widget.assignment['deadline'])}',
                  style: TextStyle(
                    color: stateAssignment == 'hoanthanh' ? Colors.green : Colors.grey,
                  ),
                ),
              ),

              if (submitData['grade'] != null)
                Center(
                  child: Text(
                    "Điểm: ${submitData['grade']}",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Mô tả:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                color: Colors.grey[50],
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                child: Text(widget.assignment['description']),
              ),
              const SizedBox(height: 16),
              const Text(
                'Đính kèm:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.black),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        if (widget.assignment['file_url'] != null) {
                          _launchURL(widget.assignment['file_url']);
                        }
                      },
                      child: Text(
                        widget.assignment['file_url'] != null
                            ? "${widget.assignment['file_url']}"
                            : 'Không có file đính kèm',
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: AppColors.primary),
              if (stateAssignment != 'hethan') ...[
                const Text(
                  'Nộp bài',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Mô tả:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                submitData.isNotEmpty && submitData['text_response'] != null ?
                Container(
                  color: Colors.grey[50],
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  child: Text(submitData['text_response']),
                ):TextField(
                  onChanged: (value) {
                    setState(() {
                      textResponse = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Nhập mô tả bài làm...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: BorderSide(color: Colors.white30)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(0),
                        borderSide: BorderSide(color: AppColors.primary)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Đính kèm:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ButtonStyle(
                        minimumSize:
                            WidgetStateProperty.all<Size>(Size(40, 50)),
                        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        backgroundColor:
                            WidgetStateProperty.all<Color>(AppColors.primary),
                      ),
                      onPressed:   _pickFile,
                      child: const Icon(Icons.attach_file, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                         submitData.isNotEmpty && submitData['file_url'] != null ? submitData['file_url'] :  selectedFile != null
                             ? selectedFile!.path.split('/').last
                             : 'Chưa chọn file',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
               if(stateAssignment != 'hoanthanh')  Center(
                 child: ElevatedButton(
                   onPressed: _submitAssignment,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     padding: const EdgeInsets.symmetric(
                         vertical: 16, horizontal: 52),
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(8),
                     ),
                   ),
                   child: const Text(
                     'Nộp bài',
                     style:
                     TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                   ),
                 ),
               ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
