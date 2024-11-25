import 'package:flutter/cupertino.dart';
import 'package:ptuddnt/presentation/screens/common/class_info.dart';
 import 'package:ptuddnt/presentation/screens/common/layout_screen.dart';
import '../presentation/screens/common/forgot_password_screen.dart';
import '../presentation/screens/lecturer/attendance_screen_lecture.dart';
import '../presentation/screens/lecturer/class/detail_class_screen_lec.dart';
import '../presentation/screens/lecturer/class/register_class_screen.dart';
import '../presentation/screens/common/login_screen.dart';
import '../presentation/screens/common/register_screen.dart';
import '../presentation/screens/common/splash_screen.dart';
import '../presentation/screens/student/absence_request/request_absence_student.dart';
import '../presentation/screens/student/class/absent_record_screen.dart';
import '../presentation/screens/student/class/detail_assignment_screen.dart';
import '../presentation/screens/student/class/detail_class_screen_student.dart';
import '../presentation/screens/student/class/list_assignment.dart';
import '../presentation/screens/common/information_user.dart';
import '../presentation/screens/lecturer/absence_review/review_absence_request.dart';


class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/home': (context) => const LayoutScreen(),
    '/register': (context) => const RegisterScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),



    '/class-detail-lecture': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>;
      return DetailClassScreenLec(classData: classData);
    },
    '/class-detail-student': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>;
      return DetailClassScreenStudent(classData: classData);
    },
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
    '/information': (context) {
      final userId = ModalRoute.of(context)!.settings.arguments as String;
      return InfoScreen(userId: userId);
    },
    '/absent-record-student': (context) {
      final classId = ModalRoute.of(context)!.settings.arguments as String;
      return AttendanceRecordScreen(classId: classId);
    },
    '/manager_absence_request': (context) {
      final classId = ModalRoute.of(context)!.settings.arguments as String;
      return ReviewRequestScreen(classId: classId);
    },
    '/history_absence_request': (context) {
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
