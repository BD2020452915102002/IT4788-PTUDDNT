import 'package:flutter/material.dart';
import 'package:ptuddnt/presentation/screens/forgot_password_screen.dart';
import 'package:ptuddnt/presentation/screens/lecturer/class/detail_class_screen_lec.dart';
import 'package:ptuddnt/presentation/screens/student/class/detail_assignment_screen.dart';
import 'package:ptuddnt/presentation/screens/student/class/detail_class_screen_student.dart';
import 'package:ptuddnt/presentation/screens/student/home_screen_student.dart';
import 'package:ptuddnt/presentation/screens/splash_screen.dart';
import 'package:ptuddnt/presentation/screens/login_screen.dart';
import 'package:ptuddnt/presentation/screens/register_screen.dart';
// import '../presentation/screens/lecturer/class/assignment/assignment.dart';
import '../presentation/screens/lecturer/home_screen_lecture.dart';
import '../presentation/screens/student/class/list_assignment.dart';
import '../presentation/screens/lecturer/register_class_screen.dart';
import '../presentation/screens/lecturer/attendance_screen_lecture.dart';
import 'package:ptuddnt/presentation/screens/student/class/absent_record_screen.dart';

class AppRoutes {
  static final Map<String, WidgetBuilder> routes = {
    '/': (context) => const SplashScreen(),
    '/login': (context) => const LoginScreen(),
    '/home-student': (context) => const HomeScreenStudent(),
    '/home-lecturer': (context) => const HomeScreenLec(),
    '/class-detail-lecture': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return DetailClassScreenLec(classData: classData);
    },
    '/class-detail-student': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return DetailClassScreenStudent(classData: classData);
    },
    '/register': (context) => const RegisterScreen(),
    '/forgot-password': (context) => const ForgotPasswordScreen(),

    '/list-assignment-student': (context) {
      final classData = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
      return ListAssignment(classData: classData);
    },
    '/detail-assignment-student': (context) {
          final assignment = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AssignmentDetailScreen(assignment: assignment);
        },
    '/absent-record-student': (context) => const AttendanceRecordScreen(),

    '/create-class-lecturer': (context) => const RegisterClassLecturer(),
    '/attendance-screen-lecturer': (context) => const AttendanceLectureScreen(),


  };
}
