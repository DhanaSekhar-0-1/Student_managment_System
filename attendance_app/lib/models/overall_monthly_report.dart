class OverallMonthlyReport {
  final int year;
  final int month;
  final String monthName;
  final DateRange dateRange;
  final MonthSummary summary;
  final List<StudentMonthlyData> students;

  OverallMonthlyReport({
    required this.year,
    required this.month,
    required this.monthName,
    required this.dateRange,
    required this.summary,
    required this.students,
  });

  factory OverallMonthlyReport.fromJson(Map<String, dynamic> json) {
    return OverallMonthlyReport(
      year: _parseInt(json['year']),
      month: _parseInt(json['month']),
      monthName: json['month_name']?.toString() ?? '',
      dateRange: DateRange.fromJson(json['date_range'] ?? {}),
      summary: MonthSummary.fromJson(json['summary'] ?? {}),
      students: (json['students'] as List?)
              ?.map((s) => StudentMonthlyData.fromJson(s))
              .toList() ??
          [],
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

class DateRange {
  final String startDate;
  final String endDate;

  DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      startDate: json['start_date']?.toString() ?? '',
      endDate: json['end_date']?.toString() ?? '',
    );
  }
}

class MonthSummary {
  final int totalStudents;
  final int totalWorkingDays;
  final int totalPresent;
  final int totalAbsent;
  final double overallPercentage;
  final int studentsAbove75;
  final int studentsBelow75;

  MonthSummary({
    required this.totalStudents,
    required this.totalWorkingDays,
    required this.totalPresent,
    required this.totalAbsent,
    required this.overallPercentage,
    required this.studentsAbove75,
    required this.studentsBelow75,
  });

  factory MonthSummary.fromJson(Map<String, dynamic> json) {
    return MonthSummary(
      totalStudents: _parseInt(json['total_students']),
      totalWorkingDays: _parseInt(json['total_working_days']),
      totalPresent: _parseInt(json['total_present']),
      totalAbsent: _parseInt(json['total_absent']),
      overallPercentage: _parseDouble(json['overall_percentage']),
      studentsAbove75: _parseInt(json['students_above_75']),
      studentsBelow75: _parseInt(json['students_below_75']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get percentageText => '${overallPercentage.toStringAsFixed(1)}%';
}

class StudentMonthlyData {
  final String studentId;
  final String studentName;
  final String pinNo;
  final String collegeName;
  final int totalWorkingDays;
  final int present;
  final int absent;
  final double attendancePercentage;
  final String status;

  StudentMonthlyData({
    required this.studentId,
    required this.studentName,
    required this.pinNo,
    required this.collegeName,
    required this.totalWorkingDays,
    required this.present,
    required this.absent,
    required this.attendancePercentage,
    required this.status,
  });

  factory StudentMonthlyData.fromJson(Map<String, dynamic> json) {
    return StudentMonthlyData(
      studentId: json['student_id']?.toString() ?? '',
      studentName: json['student_name']?.toString() ?? '',
      pinNo: json['pin_no']?.toString() ?? '',
      collegeName: json['college_name']?.toString() ?? '',
      totalWorkingDays: _parseInt(json['total_working_days']),
      present: _parseInt(json['present']),
      absent: _parseInt(json['absent']),
      attendancePercentage: _parseDouble(json['attendance_percentage']),
      status: json['status']?.toString() ?? 'NO_DATA',
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String get percentageText => '${attendancePercentage.toStringAsFixed(1)}%';
  
  String get initials {
    final names = studentName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return studentName.isNotEmpty ? studentName.substring(0, 1).toUpperCase() : '?';
  }
}