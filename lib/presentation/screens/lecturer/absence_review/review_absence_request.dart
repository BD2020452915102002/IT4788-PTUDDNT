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
  final int _itemsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _fetchAbsenceRequests();
  }

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
          "page_size": _itemsPerPage.toString(),
        }
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final pageContent = data['data']['page_content'];
      final pageInfo = data['data']['page_info'];

      setState(() {
        _absenceRequests.clear();
        _absenceRequests.addAll(pageContent);
        _hasMoreData = _currentPage < int.parse(pageInfo['total_page']) - 1;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load data')),
      );
    }
  }

  void _goToNextPage() {
    if (_hasMoreData) {
      setState(() {
        _currentPage++;
      });
      _fetchAbsenceRequests();
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
      _fetchAbsenceRequests();
    }
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _currentPage = 0;
      _absenceRequests.clear();
      _hasMoreData = true;
    });
    await _fetchAbsenceRequests();
  }

  Future<void> _updateAbsenceRequestStatus(String requestId, String status) async {
    final token = Token().get();
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
          "Quản lý nghỉ học",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        child: _isLoading ?
          Center(child:CircularProgressIndicator())
          : Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _absenceRequests.length,
                itemBuilder: (context, index) {
                  final request = _absenceRequests[index];
                  final isPending = request['status'] == 'PENDING';
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${request['student_account']['last_name']} ${request['student_account']['first_name']}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("ID: ${request['student_account']['student_id']}"),
                          Text("Email: ${request['student_account']['email']}"),
                          Text("Ngày xin nghỉ: ${request['absence_date']}"),
                        ],
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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: Icon(Icons.chevron_left),
                      onPressed: _goToPreviousPage,
                    ),
                  Text("Page ${_currentPage + 1}"),
                  if (_hasMoreData)
                    IconButton(
                      icon: Icon(Icons.chevron_right),
                      onPressed: _goToNextPage,
                    ),
                ],
              ),
            ),
          ],
        ),
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
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: StatefulBuilder(
                  builder: (context, setState) {
                    return SingleChildScrollView(
                      child: AlertDialog(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
                        title: Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Center(child: Text("${request['title']}")),
                        ),
                        content: IntrinsicHeight(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    text: 'Sinh viên: ',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "${request['student_account']['last_name']} ${request['student_account']['first_name']}",
                                        style: TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    text: 'ID: ',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "${request['student_account']['student_id']}",
                                        style: TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    text: 'Email: ',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "${request['student_account']['email']}",
                                        style: TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    text: 'Ngày xin nghỉ: ',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "${request['absence_date']}",
                                        style: TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                RichText(
                                  text: TextSpan(
                                    text: 'Lý do: ',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                                    children: [
                                      TextSpan(
                                        text: "${request['reason']}",
                                        style: TextStyle(fontWeight: FontWeight.normal),
                                      ),
                                    ],
                                  ),
                                ),
                                if (request['file_url'] != null)
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        final link = convertToDirectDownloadLink(request['file_url']);
                                        setState(() {
                                          imageUrl = link;
                                        });
                                      },
                                      child: Text(
                                        "View attached file",
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.red,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
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
                      ),
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
