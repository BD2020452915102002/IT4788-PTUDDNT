import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/colors.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final Map<String, dynamic> assignment;
  const AssignmentDetailScreen({super.key, required this.assignment});

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
             Column(
               mainAxisAlignment: MainAxisAlignment.center,
               crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      assignment['title'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (assignment['deadline'] != null)
                      Text(
                        "Hạn chót: ${formatDeadline(assignment['deadline'])}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey , fontWeight: FontWeight.w600),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
            Column(
              children: [
                Text('Mô tả')
              ],
            )
          ],
        )
      ),
    );
  }

  String formatDeadline(String deadline) {
    final deadlineDate = DateTime.parse(deadline);
    return DateFormat('dd-MM-yyyy, HH:mm').format(deadlineDate);
  }
}
