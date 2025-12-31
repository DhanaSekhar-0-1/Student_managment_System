import 'student.dart';

class MonthlyReport {
  final Student student;
  final MonthlyReportData report;
  final List<DailyRecord> dailyRecords;

  MonthlyReport({
    required this.student,
    required this.report,
    required this.dailyRecords,
  });

  factory MonthlyReport.fromJson(Map<String, dynamic> json) {
    return MonthlyReport(
      student: Student.fromJson(json['student'] as Map<String, dynamic>),
      report: MonthlyReportData.fromJson(json['report'] as Map<String, dynamic>),
      dailyRecords: (json['daily_records'] as List)
          .map((r) => DailyRecord.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MonthlyReportData {
  final int year;
  final int month;
  final String monthName;
  final int totalWorkingDays;
  final int presentCount;
  final int absentCount;
  final double attendancePercentage;
  final double absentPercentage;

  MonthlyReportData({
    required this.year,
    required this.month,
    required this.monthName,
    required this.totalWorkingDays,
    required this.presentCount,
    required this.absentCount,
    required this.attendancePercentage,
    required this.absentPercentage,
  });

  factory MonthlyReportData.fromJson(Map<String, dynamic> json) {
    return MonthlyReportData(
      year: _parseInt(json['year']),
      month: _parseInt(json['month']),
      monthName: json['month_name']?.toString() ?? '', // ✅ Fixed null handling
      totalWorkingDays: _parseInt(json['total_working_days']),
      presentCount: _parseInt(json['present_count']),
      absentCount: _parseInt(json['absent_count']),
      attendancePercentage: _parseDouble(json['attendance_percentage']),
      absentPercentage: _parseDouble(json['absent_percentage']),
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
}

class DailyRecord {
  final String date;
  final String day;
  final String status;
  final String? time;

  DailyRecord({
    required this.date,
    required this.day,
    required this.status,
    this.time,
  });

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: json['date']?.toString() ?? '', // ✅ Fixed null handling
      day: json['day']?.toString() ?? '',   // ✅ Fixed null handling
      status: json['status']?.toString() ?? 'N/A', // ✅ Fixed null handling
      time: json['time']?.toString(),
    );
  }

  bool get isPresent => status == 'PRESENT';
  bool get isAbsent => status == 'ABSENT';
  bool get isSunday => status == 'SUNDAY';
  bool get isNA => status == 'N/A';
}

class OverallReport {
  final Student student;
  final OverallSummary overallSummary;
  final List<MonthlyBreakdown> monthlyBreakdown;

  OverallReport({
    required this.student,
    required this.overallSummary,
    required this.monthlyBreakdown,
  });

  factory OverallReport.fromJson(Map<String, dynamic> json) {
    return OverallReport(
      student: Student.fromJson(json['student'] as Map<String, dynamic>),
      overallSummary: OverallSummary.fromJson(json['overall_summary'] as Map<String, dynamic>),
      monthlyBreakdown: (json['monthly_breakdown'] as List)
          .map((m) => MonthlyBreakdown.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

class OverallSummary {
  final int totalWorkingDays;
  final int presentCount;
  final int absentCount;
  final double attendancePercentage;
  final String? firstAttendanceDate;
  final String? lastAttendanceDate;
  final int daysEnrolled;

  OverallSummary({
    required this.totalWorkingDays,
    required this.presentCount,
    required this.absentCount,
    required this.attendancePercentage,
    this.firstAttendanceDate,
    this.lastAttendanceDate,
    required this.daysEnrolled,
  });

  factory OverallSummary.fromJson(Map<String, dynamic> json) {
    return OverallSummary(
      totalWorkingDays: _parseInt(json['total_working_days']),
      presentCount: _parseInt(json['present_count']),
      absentCount: _parseInt(json['absent_count']),
      attendancePercentage: _parseDouble(json['attendance_percentage']),
      firstAttendanceDate: json['first_attendance_date']?.toString(),
      lastAttendanceDate: json['last_attendance_date']?.toString(),
      daysEnrolled: _parseInt(json['days_enrolled']),
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
}

class MonthlyBreakdown {
  final int year;
  final int month;
  final String monthName;
  final int present;
  final int absent;
  final double percentage;

  MonthlyBreakdown({
    required this.year,
    required this.month,
    required this.monthName,
    required this.present,
    required this.absent,
    required this.percentage,
  });

  factory MonthlyBreakdown.fromJson(Map<String, dynamic> json) {
    return MonthlyBreakdown(
      year: _parseInt(json['year']),
      month: _parseInt(json['month']),
      monthName: json['month_name']?.toString() ?? '', // ✅ Fixed null handling
      present: _parseInt(json['present']),
      absent: _parseInt(json['absent']),
      percentage: _parseDouble(json['percentage']),
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

  String get percentageText => '${percentage.toStringAsFixed(1)}%';
}