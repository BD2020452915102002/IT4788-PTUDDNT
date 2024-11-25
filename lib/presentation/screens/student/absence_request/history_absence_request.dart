import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/core/utils/hive.dart';

class HistoryAbsenceRequest extends StatefulWidget {
  final String classId;

  const HistoryAbsenceRequest({super.key, required this.classId});

  @override
  HistoryRequestScreenState createState() => HistoryRequestScreenState();
}

class HistoryRequestScreenState extends State<HistoryAbsenceRequest> {
  int currentPage = 0;
  int pageSize = 4;
  int totalPages = 0;
  List absenceRequests = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    final requestData = HiveService().getData('requestData-${currentPage}');
    if (requestData == null) {
     await fetchAbsenceRequests();
    }
    final ttt = HiveService().getData('requestData_page_info')['total_page'];
    final dddd = HiveService().getData('requestData');
    setState(() {
      absenceRequests = dddd;
      isLoading = false;
      totalPages = int.parse(ttt);
    });
  }

  Future<void> fetchAbsenceRequests({bool isRefresh = false}) async {
    setState(() {
      isLoading = true;
    });
    await HiveService().deleteData('requestData_page_info');

    final response = await http.post(
      Uri.parse(
          'http://157.66.24.126:8080/it5023e/get_student_absence_requests'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "token": Token().get(),
        "class_id": widget.classId,
        "status": null,
        "pageable_request": {
          "page": currentPage.toString(),
          "page_size": pageSize.toString()
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes))['data'];
      await HiveService().saveData('requestData-${currentPage}', data['page_content'] as List);
      await HiveService().saveData('requestData_page_info', data['page_info']);
    } else {
      throw Exception("Failed to load absence requests");
    }

    setState(() {
      isLoading = false;
    });
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'ACCEPTED':
        return Colors.green;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _refresh() async {
    for (int i =0; i < totalPages; i++) {
      await HiveService().deleteData('requestData-${i}');
    }
    setState(() {
      currentPage = 0;
    });
    await fetchAbsenceRequests(isRefresh: true);
    setState(() {
      absenceRequests = HiveService().getData('requestData');
    });
  }

  String convertToDirectDownloadLink(String driveLink) {
    final regex = RegExp(r'file/d/([a-zA-Z0-9_-]+)');
    final match = regex.firstMatch(driveLink);

    if (match != null && match.groupCount > 0) {
      final fileId = match.group(1);
      return 'https://drive.google.com/uc?export=view&id=$fileId';
    } else {
      throw ArgumentError('Invalid Google Drive link format');
    }
  }

  void showImageDialog(BuildContext context, String driveLink) {
    final directLink = convertToDirectDownloadLink(driveLink);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text('Ảnh Minh Chứng'),
              const SizedBox(height: 20),
              Image.network(
                directLink,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (BuildContext context, Object error,
                    StackTrace? stackTrace) {
                  return const Text('Không thể tải ảnh');
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.tertiary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lịch sử xin nghỉ",
          style: TextStyle(
            color: AppColors.tertiary,
            fontStyle: FontStyle.normal,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: isLoading ?
            Center(child:CircularProgressIndicator())
            :Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: absenceRequests.length,
                itemBuilder: (context, index) {
                  final absenceRequest = absenceRequests[index];
                  return Card(
                    margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            absenceRequest['title'],
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              "Ngày xin nghỉ: ${absenceRequest['absence_date']}"),
                          const SizedBox(height: 8),
                          Text("Lý do: ${absenceRequest['reason']}"),
                          const SizedBox(height: 8),
                          if (absenceRequest['file_url'] != null)
                            GestureDetector(
                              onTap: () {
                                showImageDialog(context,
                                    absenceRequest['file_url'] as String);
                              },
                              child: const Text(
                                "Xem ảnh minh chứng",
                                style: TextStyle(
                                    color: Colors.blue,
                                    decoration: TextDecoration.underline),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Trạng thái:"),
                              Text(
                                absenceRequest['status'],
                                style: TextStyle(
                                  color:
                                  getStatusColor(absenceRequest['status']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: currentPage > 0
                        ? () async {
                      setState(() {
                        currentPage--;
                      });
                      final aaa  = HiveService().getData('requestData-${currentPage}');
                      if(aaa == null) {
                        await fetchAbsenceRequests();

                      }
                      setState(() {
                        absenceRequests =
                            HiveService().getData('requestData-${currentPage}');
                      });
                    }
                        : null,
                  ),
                  Text("Trang ${currentPage + 1} / $totalPages"),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: currentPage < totalPages
                        ? () async {
                      setState(() {
                        currentPage++;
                      });
                      final aaa  = HiveService().getData('requestData-${currentPage}');
                      if(aaa == null) {
                        await fetchAbsenceRequests();

                      }
                      setState(() {
                        absenceRequests =
                            HiveService().getData('requestData-${currentPage}');
                      });
                    }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
