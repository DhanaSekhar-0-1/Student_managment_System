import 'package:flutter/foundation.dart';

class ApiConfig {
  // Base URL - different for web and mobile
  static const String baseUrl = kIsWeb
      ? 'http://localhost:3000/api'
      : 'http://122.169.206.214:3000/api';

  // Timeout duration
  static const Duration timeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Student Endpoints
  static const String students = '/students';
  static const String studentById = '/students'; // + /{id}
  static const String studentByNfc = '/students/by-nfc'; // + /{nfc_id}
  static const String colleges = '/students/colleges';
  static const String studentsActivate = '/students'; // + /{id}/activate
  static const String studentsDeactivate = '/students'; // + /{id}/deactivate

  // Attendance Endpoints
  static const String attendanceToday = '/attendance/today';
  static const String attendanceMark = '/attendance/mark';
  static const String attendanceStudent = '/attendance/student'; // + /{student_id_no}
  static const String attendanceRange = '/attendance/range';
  static const String attendanceUpdate = '/attendance'; // + /{id}
  static const String attendanceAutoAbsent = '/attendance/auto-absent';

  // Report Endpoints
  static const String reportsMonthly = '/reports/monthly'; // + /{student_id_no}
  static const String reportsOverall = '/reports/overall'; // + /{student_id_no}
  static const String reportsOverallMonthly = '/reports/overall-monthly';
  static const String reportsCollege = '/reports/college'; // + /{college_name}
}