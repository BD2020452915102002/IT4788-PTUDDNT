class Assignment {
  final int id;
  final String title;
  final String description;
  final int lecturerId;
  final String classId;
  final DateTime deadline;
  final String? fileUrl;

  Assignment({
    required this.id,
    required this.title,
    required this.description,
    required this.lecturerId,
    required this.classId,
    required this.deadline,
    this.fileUrl,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      lecturerId: json['lecturer_id'],
      classId: json['class_id'],
      deadline: DateTime.parse(json['deadline']),
      fileUrl: json['file_url'],
    );
  }
}
