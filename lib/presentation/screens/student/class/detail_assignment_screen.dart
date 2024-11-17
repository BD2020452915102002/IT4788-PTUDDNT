import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ptuddnt/presentation/widgets/link_text.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/colors.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> assignment;

  const AssignmentDetailScreen({super.key, required this.assignment});

  String formatDeadline(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    return DateFormat('dd-MM-yyyy, HH:mm').format(deadlineDate);
  }
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('Could not launch $url');
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
      body: SingleChildScrollView( // Giúp cuộn màn hình khi nội dung quá dài
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  assignment['title'],
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Hạn: ${formatDeadline(assignment['deadline'])}',
                  style: const TextStyle(color: Colors.grey),
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
                child: Text(assignment['description']),
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
                        if (assignment['file_url'] != null) {
                          _launchURL(assignment['file_url']);
                        }
                      },
                      child: Text(
                        "${assignment['file_url'] ?? 'N/A'}",
                        style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 32, color: Colors.red),
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
              Container(
                height: 100,
                color: Colors.grey[300],
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
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Mô tả, yêu cầu giao diện.docx',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        filled: true,
                        fillColor: Colors.pink[50],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Nộp bài',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
