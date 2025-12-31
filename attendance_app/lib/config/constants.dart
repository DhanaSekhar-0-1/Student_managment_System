class AppConstants {
  // App Info
  static const String appName = 'Attendance System';
  static const String appVersion = '1.0.0';
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';
  static const String apiDateFormat = 'yyyy-MM-dd';
  
  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keySelectedCollege = 'selected_college';
  
  // Attendance
  static const String cutoffTime = '10:00 AM';
  static const List<String> workingDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];
  
  // Status
  static const String statusPresent = 'PRESENT';
  static const String statusAbsent = 'ABSENT';
  
  // Routes
  static const String routeSplash = '/';
  static const String routeHome = '/home';
  static const String routeDashboard = '/dashboard';
  static const String routeStudents = '/students';
  static const String routeStudentDetail = '/student-detail';
  static const String routeAddStudent = '/add-student';
  static const String routeTodayAttendance = '/today-attendance';
  static const String routeAttendanceHistory = '/attendance-history';
  static const String routeMonthlyReport = '/monthly-report';
  static const String routeOverallReport = '/overall-report';
}