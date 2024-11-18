class Assignment {
  final int id;
  final String title;
  final String description;
  final int lecturerId;
  final String classId;
  final DateTime deadline;
  final String? assignmentLink;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.lecturerId,
    required this.classId,
    required this.deadline,
    required this.assignmentLink,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      lecturerId: json['lecturer_id'],
      classId: json['class_id'],
      deadline: DateTime.parse(json['deadline']),
      assignmentLink: json['file_url'] as String? ?? 'No Link',
    );
  }
}
