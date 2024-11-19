import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/config/api_class.dart';
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final status = DateTime.parse(widget.assignment['deadline']).isBefore(now);
    if (widget.assignment['is_submitted']) {
      stateAssignment = 'hoanthanh';
    } else {
      stateAssignment = status ? 'hethan' : 'chuahoanthanh';
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
          final data = jsonDecode(res.body);
          setState(() {
            // submitData = data['data'] as Map<dynamic, dynamic>;
          });
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
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _submitAssignment() async {
    setState(() {
      loading = true;
    });

    if (selectedFile != null && textResponse != null) {
      final token = Token().get();
      final assignmentID = widget.assignment['id'].toString();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse("http://160.30.168.228:8080/it5023e/submit_survey?file"),
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
        if (response.statusCode == 200) {
          // Xử lý phản hồi thành công
          print('Bài tập đã nộp thành công!');
        } else {
          // Xử lý phản hồi lỗi
          print('Lỗi khi nộp bài tập: ${response.statusCode}');
        }
      } catch (e) {
        // Xử lý lỗi kết nối
        print('Lỗi kết nối: $e');
      } finally {
        setState(() {
          loading = false;
        });
      }
    } else {
      setState(() {
        loading = false;
      });
      print('Vui lòng chọn file và nhập mô tả!');
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
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Hạn: ${formatDeadline(widget.assignment['deadline'])}',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
             // if(submitData['submission_time'] != null)
             //   Center(
             //   child: Text(
             //     'Đã nộp: ${formatDeadline(submitData['submission_time'])}',
             //     style: const TextStyle(color: Colors.greenAccent),
             //   ),
             // ),
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
                TextField(
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
                            MaterialStateProperty.all<Size>(Size(40, 50)),
                        shape:
                            MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        backgroundColor:
                            MaterialStateProperty.all<Color>(AppColors.primary),
                      ),
                      onPressed: _pickFile,
                      child: const Icon(Icons.attach_file, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedFile != null
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
                Center(
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
