import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendanceProvider with ChangeNotifier {
  // State
  TodayAttendanceData? _todayAttendance;
  List<Attendance> _attendanceHistory = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  TodayAttendanceData? get todayAttendance => _todayAttendance;
  List<Attendance> get attendanceHistory => _attendanceHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Today's summary
  AttendanceSummary? get todaySummary => _todayAttendance?.summary;
  bool get isHoliday => _todayAttendance?.isHoliday ?? false;
  String? get holidayReason => _todayAttendance?.holidayReason;

  // Mark attendance
  Future<Map<String, dynamic>?> markAttendance({
    required String nfcId,
    String? deviceId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AttendanceService.markAttendance(
        nfcId: nfcId,
        deviceId: deviceId,
      );
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      
      // Refresh today's attendance
      await fetchTodayAttendance();
      
      return result;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Fetch today's attendance
  Future<void> fetchTodayAttendance({
    String? collegeName,
    String? status,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todayAttendance = await AttendanceService.getTodayAttendance(
        collegeName: collegeName,
        status: status,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _todayAttendance = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch student attendance history
  Future<void> fetchStudentAttendance({
    required String studentIdNo,
    String? startDate,
    String? endDate,
    int? month,
    int? year,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await AttendanceService.getStudentAttendance(
        studentIdNo: studentIdNo,
        startDate: startDate,
        endDate: endDate,
        month: month,
        year: year,
      );
      
      final List<dynamic> recordsJson = result['records'];
      _attendanceHistory = recordsJson
          .map((r) => Attendance.fromJson(r))
          .toList();
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _attendanceHistory = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update attendance
  Future<bool> updateAttendance({
    required int attendanceId,
    String? status,
    String? attendanceTime,
    String? remarks,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await AttendanceService.updateAttendance(
        attendanceId: attendanceId,
        status: status,
        attendanceTime: attendanceTime,
        remarks: remarks,
      );
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset
  void reset() {
    _todayAttendance = null;
    _attendanceHistory = [];
    _isLoading = false;
    _error = null;
    notifyListeners();
  }
}