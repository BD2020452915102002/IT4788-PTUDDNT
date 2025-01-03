import 'dart:convert';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ptuddnt/core/config/api_class.dart';
import 'package:ptuddnt/core/constants/colors.dart';
import 'package:ptuddnt/core/utils/hive.dart';
import 'package:ptuddnt/core/utils/token.dart';

class ListAssignment extends StatefulWidget {
  const ListAssignment({super.key});

  @override
  State<ListAssignment> createState() => _ListAssignmentState();
}

class _ListAssignmentState extends State<ListAssignment>
    with TickerProviderStateMixin {
  List<dynamic> upcomingAssignments = [];
  List<dynamic> pastAssignments = [];
  List<dynamic> completedAssignments = [];
  bool isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeData();
  }

  Future<void> _initializeData() async {
    final upcoming = HiveService().getData('chuahoanthanh');
    final past = HiveService().getData('hethan');
    final completed = HiveService().getData('hoanthanh');
    final bool isFetch = (upcoming == null || upcoming.isEmpty) &&
        (past == null || past.isEmpty) &&
        (completed == null || completed.isEmpty);
    if (isFetch) {
      await fetchAssignments();
    }
    setState(() {
      upcomingAssignments = HiveService().getData('chuahoanthanh');
      pastAssignments = HiveService().getData('hethan');
      completedAssignments = HiveService().getData('hoanthanh');
      isLoading = false;
    });
  }

  Future<void> fetchAssignments() async {
    setState(() {
      isLoading = true;
    });
    final response = await ApiClass().post('/get_student_assignments', {
      "token": Token().get(),
    });
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      setState(() {
        final allAssignments = data['data'];
        final now = DateTime.now();

        completedAssignments = allAssignments
            .where((assignment) => assignment['is_submitted'] == true)
            .toList();

        final notCompletedAssignments = allAssignments
            .where((assignment) => assignment['is_submitted'] != true)
            .toList();

        upcomingAssignments = notCompletedAssignments
            .where((assignment) =>
                DateTime.parse(assignment['deadline']).isAfter(now))
            .toList();

        pastAssignments = notCompletedAssignments
            .where((assignment) =>
                DateTime.parse(assignment['deadline']).isBefore(now))
            .toList();
        HiveService().saveData('hoanthanh', completedAssignments);
        HiveService().saveData('chuahoanthanh', upcomingAssignments);
        HiveService().saveData('hethan', pastAssignments);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      throw Exception('Failed to load assignments');
    }
  }

  Future<void> onRefresh() async {
    HiveService().deleteData('hoanthanh');
    HiveService().deleteData('chuahoanthanh');
    HiveService().deleteData('hethan');
    await fetchAssignments();
    setState(() {
      upcomingAssignments = HiveService().getData('chuahoanthanh');
      pastAssignments = HiveService().getData('hethan');
      completedAssignments = HiveService().getData('hoanthanh');
      isLoading = false;
    });
  }

  // Future<void> onLoad ()async{
  //   final pageInfor =   HiveService().getData('page_info');
  //   if(pageInfor['next_page'] == null){
  //     // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đã hết lớp học')));
  //   } else {
  //     setState(() {
  //       page ++ ;
  //     });
  //     await loadMoreClassList();
  //     setState(() {
  //       _classList = HiveService().getData('page_content');
  //     });
  //   }
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 60,
        centerTitle: true,
        backgroundColor: AppColors.primary,
        leading: null,
        title: const Text(
          "Danh sách bài tập",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          // TabBar đặt ở body
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "Còn hạn"),
                Tab(text: "Hết hạn"),
                Tab(text: "Đã hoàn thành"),
              ],
              labelColor: AppColors.primary,
              unselectedLabelColor: Colors.black,
              indicatorColor: AppColors.primary,
            ),
          ),
          // TabBarView hiển thị các bài tập theo từng tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAssignmentList(upcomingAssignments),
                _buildAssignmentList(pastAssignments),
                _buildAssignmentList(completedAssignments),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String formatDeadline(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    return DateFormat('dd-MM-yyyy, HH:mm').format(deadlineDate);
  }

  String _getTimeRemaining(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    final now = DateTime.now();
    final difference = deadlineDate.difference(now);

    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      final days = difference.inDays % 30;
      return '$months tháng, ${days > 0 ? '$days ngày' : ''} còn lại';
    } else if (difference.inDays > 0) {
      final hours = difference.inHours % 24;
      return '${difference.inDays} ngày, ${hours > 0 ? '$hours giờ' : ''} còn lại';
    } else if (difference.inHours > 0) {
      final minutes = difference.inMinutes % 60;
      return '${difference.inHours} giờ, ${minutes > 0 ? '$minutes phút' : ''} còn lại';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} phút còn lại';
    } else {
      return 'Đã hết hạn';
    }
  }

  Widget _buildAssignmentList(List<dynamic> assignments) {
    return EasyRefresh(
        onRefresh: onRefresh,
        // onLoad: onLoad,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: assignments.length,
                itemBuilder: (context, index) {
                  final assignment =
                      assignments[index] as Map<dynamic, dynamic>;
                  return GestureDetector(
                    onTap: () async {
                      final result =
                          await Navigator.of(context, rootNavigator: true)
                              .pushNamed(
                        '/detail-assignment-student',
                        arguments: assignment,
                      );
                      if (result != null) {
                        print(' vào day duc');
                        await fetchAssignments();
                        setState(() {
                          upcomingAssignments =
                              HiveService().getData('chuahoanthanh');
                          pastAssignments = HiveService().getData('hethan');
                          completedAssignments =
                              HiveService().getData('hoanthanh');
                          isLoading = false;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text(
                              assignment['title'] ?? '',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              assignment['description'] ?? '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  assignment['deadline'] != null
                                      ? formatDeadline(assignment['deadline'])
                                      : '',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (assignment['deadline'] != null)
                                  Text(
                                    _getTimeRemaining(assignment['deadline']),
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ));
  }
}
