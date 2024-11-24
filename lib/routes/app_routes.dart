import 'package:flutter/cupertino.dart';
import 'package:path/path.dart';
import 'package:ptuddnt/presentation/screens/class_info.dart';
import '../presentation/screens/forgot_password_screen.dart';
import '../presentation/screens/lecturer/attendance_screen_lecture.dart';
import '../presentation/screens/lecturer/class/detail_class_screen_lec.dart';
import '../presentation/screens/lecturer/home_screen_layout_lec.dart';
import '../presentation/screens/lecturer/register_class_screen.dart';
import '../presentation/screens/login_screen.dart';
import '../presentation/screens/register_screen.dart';
import '../presentation/screens/splash_screen.dart';
import '../presentation/screens/student/absence_request/request_absence_student.dart';
import '../presentation/screens/student/class/absent_record_screen.dart';
import '../presentation/screens/student/class/detail_assignment_screen.dart';
import '../presentation/screens/student/class/detail_class_screen_student.dart';
import '../presentation/screens/student/class/list_assignment.dart';
import '../presentation/screens/student/home_screen_layout_stu.dart';
import '../presentation/screens/student/information_student_screen.dart';
import '../presentation/screens/lecturer/absence_review/review_absence_request.dart';


class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/home-student': (context) => const HomeStudent(),
    '/home-lecturer': (context) => const HomeLectuter(),
    '/class-detail-lecture': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>;
      return DetailClassScreenLec(classData: classData);
    },

    '/class-detail-student': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>;
      return DetailClassScreenStudent(classData: classData);
    },
    '/register': (context) => const RegisterScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),

    '/list-assignment-student': (context) {
      return ListAssignment();
    },
    '/detail-assignment-student': (context) {
      final assignment = ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>;
      return AssignmentDetailScreen(assignment: assignment);
    },
    '/request-absence': (context) {
      final classId = ModalRoute.of(context)!.settings.arguments as String;
      return LeaveRequestScreen(classId: classId);
    },
    '/class-info': (context) {
      final classId = ModalRoute.of(context)!.settings.arguments as String;
      return ClassInfo(classId: classId);
    },
    '/information-student': (context) {
      final userId = ModalRoute.of(context)!.settings.arguments as String;
      return StudentInfoScreen(userId: userId);
    },
    '/absent-record-student': (context) {
      final classId = ModalRoute.of(context)!.settings.arguments as String;
      return AttendanceRecordScreen(classId: classId);
    },
    '/manager_absence_request': (context) {
      final classId = ModalRoute.of(context)!.settings.arguments as String;
      return ReviewRequestScreen(classId: classId);
    },
    '/create-class-lecturer': (context) => const RegisterClassLecturer(),
    '/attendance-screen-lecturer': (context) {
      final classId = ModalRoute.of(context)!.settings.arguments as String;
      return AttendanceLectureScreen(classId: classId);
    }

  };
}
