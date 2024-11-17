class AbsenceRequest {
  final String studentName;
  final String studentId;
  final String className;
  final DateTime? absenceDate;
  final String reason;

  AbsenceRequest({
    required this.studentName,
    required this.studentId,
    required this.className,
    this.absenceDate,
    required this.reason,
  });

  Map<String, dynamic> toJson() => {
    'student_name': studentName,
    'student_id': studentId,
    'class_name': className,
    'absence_date': absenceDate?.toIso8601String(),
    'reason': reason,
  };
}
