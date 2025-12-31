import '../models/attendance.dart';
import 'api_service.dart';

class AttendanceService {
  static Future<Map<String, dynamic>> markAttendance({
    required String nfcId,
    String? deviceId,
  }) async {
    final body = {
      'nfc_id': nfcId,
      if (deviceId != null) 'device_id': deviceId,
    };

    final response = await ApiService.post('/attendance/mark', body);
    return response['data'];
  }

  static Future<TodayAttendanceData> getTodayAttendance({
    String? collegeName,
    String? status,
  }) async {
    String endpoint = '/attendance/today';
    
    final params = <String>[];
    if (collegeName != null && collegeName.isNotEmpty) {
      params.add('college_name=${Uri.encodeComponent(collegeName)}');
    }
    if (status != null && status.isNotEmpty) {
      params.add('status=$status');
    }
    
    if (params.isNotEmpty) {
      endpoint += '?${params.join('&')}';
    }

    final response = await ApiService.get(endpoint);
    return TodayAttendanceData.fromJson(response['data']);
  }

  static Future<Map<String, dynamic>> getStudentAttendance({
    required String studentIdNo,
    String? startDate,
    String? endDate,
    int? month,
    int? year,
    int page = 1,
    int limit = 30,
  }) async {
    String endpoint = '/attendance/student/$studentIdNo?page=$page&limit=$limit';
    
    if (startDate != null && endDate != null) {
      endpoint += '&start_date=$startDate&end_date=$endDate';
    } else if (month != null && year != null) {
      endpoint += '&month=$month&year=$year';
    } else if (year != null) {
      endpoint += '&year=$year';
    }

    final response = await ApiService.get(endpoint);
    return response['data'];
  }

  static Future<Map<String, dynamic>> getAttendanceByDateRange({
    required String startDate,
    required String endDate,
    String? collegeName,
    String? studentIdNo,
  }) async {
    String endpoint = '/attendance/range?start_date=$startDate&end_date=$endDate';
    
    if (collegeName != null && collegeName.isNotEmpty) {
      endpoint += '&college_name=${Uri.encodeComponent(collegeName)}';
    }
    if (studentIdNo != null && studentIdNo.isNotEmpty) {
      endpoint += '&student_id_no=$studentIdNo';
    }

    final response = await ApiService.get(endpoint);
    return response['data'];
  }

  static Future<Attendance> updateAttendance({
    required int attendanceId,
    String? status,
    String? attendanceTime,
    String? remarks,
  }) async {
    final body = <String, dynamic>{};
    
    if (status != null) body['status'] = status;
    if (attendanceTime != null) body['attendance_time'] = attendanceTime;
    if (remarks != null) body['remarks'] = remarks;

    final response = await ApiService.patch('/attendance/$attendanceId', body);
    return Attendance.fromJson(response['data']['attendance']);
  }
}