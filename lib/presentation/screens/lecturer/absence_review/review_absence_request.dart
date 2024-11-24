import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ptuddnt/core/utils/token.dart';
import 'package:ptuddnt/core/constants/colors.dart';



class ReviewRequestScreen extends StatefulWidget {
  final String classId;

  const ReviewRequestScreen({super.key, required this.classId});

  @override
  ReviewRequestScreenState createState() => ReviewRequestScreenState();
}

class ReviewRequestScreenState extends State<ReviewRequestScreen> {
  int _currentPage = 0;
  final List _absenceRequests = [];
  bool _isLoading = false;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();
    _fetchAbsenceRequests();
  }

  // Lấy dữ liệu từ API
  Future<void> _fetchAbsenceRequests() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final token = Token().get();
    final url = Uri.parse("http://157.66.24.126:8080/it5023e/get_absence_requests");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "token": token,
        "class_id": widget.classId,
        "status": null,
        "pageable_request": {
          "page": _currentPage.toString(),
          "page_size": "2"
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final pageContent = data['data']['page_content'];
      final pageInfo = data['data']['page_info'];

      setState(() {
        _absenceRequests.addAll(pageContent);
        _hasMoreData = _currentPage < int.parse(pageInfo['total_page']) - 1;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      // Handle error (e.g., show a Snackbar)
    }
  }

  Future<void> _updateAbsenceRequestStatus(String requestId, String status) async {
    final token = await Token().get();
    final url = Uri.parse("http://157.66.24.126:8080/it5023e/review_absence_request");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        "token": token,
        "request_id": requestId,
        "status": status,
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        // Cập nhật lại trạng thái yêu cầu trong danh sách
        var request = _absenceRequests.firstWhere((request) => request['id'] == requestId);
        request['status'] = status;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update request')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Xin phép nghỉ học",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _absenceRequests.length + 1,
              itemBuilder: (context, index) {
                if (index == _absenceRequests.length) {
                  return _hasMoreData
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox.shrink();
                }

                final request = _absenceRequests[index];
                final isPending = request['status'] == 'PENDING';

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    title: Text(
                      "${request['student_account']['last_name']} ${request['student_account']['first_name']}",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("Reason: ${request['reason']}"),
                    trailing: Text(
                      request['status'],
                      style: TextStyle(
                        fontWeight: isPending ? FontWeight.bold : FontWeight.normal,
                        color: isPending ? Colors.orange : Colors.black,
                      ),
                    ),
                    onTap: () => _showRequestDetails(request),
                  ),
                );
              },
            ),
          ),
          if (_isLoading) CircularProgressIndicator(),
          if (_hasMoreData && !_isLoading)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentPage++;
                });
                _fetchAbsenceRequests();
              },
              child: Text("Load More"),
            ),
        ],
      ),
    );
  }

  void _showRequestDetails(Map<String, dynamic> request) {
    String? imageUrl;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Center(child: Text("${request['title']}")),
                      ),
                      content: IntrinsicHeight( // Bọc content bằng IntrinsicHeight
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Student: ${request['student_account']['last_name']} ${request['student_account']['first_name']}"),
                              Text("Date: ${request['absence_date']}"),
                              Text("Reason: ${request['reason']}"),
                              if (request['file_url'] != null)
                                TextButton(
                                  onPressed: () {
                                    final link = convertToDirectDownloadLink(request['file_url']);
                                    setState(() {
                                      imageUrl = link;
                                    });
                                  },
                                  child: Text("View attached file"),
                                ),
                              if (imageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 10.0),
                                  child: Image.network(imageUrl!),
                                ),
                            ],
                          ),
                        ),
                      ),
                      actions: [
                        if (request['status'] == 'PENDING')
                          TextButton(
                            onPressed: () {
                              _updateAbsenceRequestStatus(request['id'], "REJECTED");
                              Navigator.of(context).pop();
                            },
                            child: Text("Reject", style: TextStyle(color: Colors.red)),
                          ),
                        if (request['status'] == 'PENDING')
                          TextButton(
                            onPressed: () {
                              _updateAbsenceRequestStatus(request['id'], "ACCEPTED");
                              Navigator.of(context).pop();
                            },
                            child: Text("Accept", style: TextStyle(color: Colors.green)),
                          ),
                      ],
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
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

}
