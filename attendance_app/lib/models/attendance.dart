import 'package:intl/intl.dart';

class Attendance {
  final int attendanceId;
  final String studentIdNo;
  final String studentName;
  final String pinNo;
  final String collegeName;
  final DateTime attendanceDate;
  final String attendanceTime;
  final String status;
  final String deviceId;
  final String? remarks;
  final DateTime? createdAt;

  Attendance({
    required this.attendanceId,
    required this.studentIdNo,
    required this.studentName,
    required this.pinNo,
    required this.collegeName,
    required this.attendanceDate,
    required this.attendanceTime,
    required this.status,
    required this.deviceId,
    this.remarks,
    this.createdAt,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      attendanceId: _parseInt(json['attendance_id']),
      studentIdNo: _parseString(json['student_id_no']),
      studentName: _parseString(json['student_name']),
      pinNo: _parseString(json['pin_no']),
      collegeName: _parseString(json['college_name']),
      attendanceDate: _parseDate(json['attendance_date']),
      attendanceTime: _parseString(json['attendance_time']),
      status: _parseString(json['status']),
      deviceId: _parseString(json['device_id'], defaultValue: 'UNKNOWN'),
      remarks: json['remarks'] as String?,
      createdAt: json['created_at'] != null 
          ? _parseDateTime(json['created_at']) 
          : null,
    );
  }

  // Safe parsing helpers
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _parseString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    try {
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }

  // Helper getters
  bool get isPresent => status == 'PRESENT';
  bool get isAbsent => status == 'ABSENT';
  
  String get formattedDate => DateFormat('dd MMM yyyy').format(attendanceDate);
  String get formattedTime => attendanceTime;
  String get dayOfWeek => DateFormat('EEEE').format(attendanceDate);
}

class AttendanceSummary {
  final int total;
  final int present;
  final int absent;
  final double attendancePercentage;

  AttendanceSummary({
    required this.total,
    required this.present,
    required this.absent,
    required this.attendancePercentage,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      total: _parseInt(json['total']),
      present: _parseInt(json['present']),
      absent: _parseInt(json['absent']),
      attendancePercentage: _parseDouble(json['attendance_percentage']),
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

class TodayAttendanceData {
  final String date;
  final String dayOfWeek;
  final bool isHoliday;
  final String? holidayReason;
  final AttendanceSummary summary;
  final List<Attendance> records;

  TodayAttendanceData({
    required this.date,
    required this.dayOfWeek,
    required this.isHoliday,
    this.holidayReason,
    required this.summary,
    required this.records,
  });

  factory TodayAttendanceData.fromJson(Map<String, dynamic> json) {
    return TodayAttendanceData(
      date: json['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      dayOfWeek: json['day_of_week']?.toString() ?? 'Unknown',
      isHoliday: json['is_holiday'] == true || json['is_holiday'] == 1,
      holidayReason: json['holiday_reason'] as String?,
      summary: AttendanceSummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
      records: (json['records'] as List<dynamic>?)
              ?.map((r) => Attendance.fromJson(r as Map<String, dynamic>))
              .toList() ?? [],
    );
  }
}