// ignore_for_file: avoid_print

import 'dart:convert';
import '../config/api_config.dart';
import '../models/report.dart';
import '../models/overall_monthly_report.dart';
import 'api_service.dart';

class ReportService {
  /// Get monthly attendance report for a specific student
  static Future<MonthlyReport> getMonthlyReport({
    required String studentIdNo,
    required int year,
    required int month,
  }) async {
    try {
      print(
          '🔍 Fetching monthly report for: $studentIdNo (Year: $year, Month: $month)');

      final response = await ApiService.get(
        '${ApiConfig.reportsMonthly}/$studentIdNo',
        queryParams: {
          'year': year.toString(),
          'month': month.toString(),
        },
      );

      // Debug: Print the full response
      print('📦 Full API Response: ${jsonEncode(response)}');
      print('📊 Response Keys: ${response.keys.toList()}');
      print('📋 Data field type: ${response['data'].runtimeType}');
      print('📋 Data content: ${jsonEncode(response['data'])}');

      // Check if response is successful
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Request failed');
      }

      // Check if data exists
      if (response['data'] == null) {
        throw Exception('No data returned from server');
      }

      // Validate data structure
      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid data format received');
      }

      // Check required fields
      if (!data.containsKey('student')) {
        throw Exception('Missing student information in response');
      }
      if (!data.containsKey('report')) {
        throw Exception('Missing report information in response');
      }
      if (!data.containsKey('daily_records')) {
        throw Exception('Missing daily records in response');
      }

      print('✅ Data validation passed, parsing MonthlyReport...');

      return MonthlyReport.fromJson(data);
    } on ApiException catch (e) {
      print('❌ API Exception: ${e.message}');
      throw Exception('API Error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error fetching monthly report: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Failed to fetch monthly report: $e');
    }
  }

  /// Get overall attendance report for a specific student
  static Future<OverallReport> getOverallReport({
    required String studentIdNo,
  }) async {
    try {
      print('🔍 Fetching overall report for: $studentIdNo');

      final response = await ApiService.get(
        '${ApiConfig.reportsOverall}/$studentIdNo',
      );

      // Debug logging
      print('📦 Overall Report Response: ${jsonEncode(response)}');

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Request failed');
      }

      if (response['data'] == null) {
        throw Exception('No data returned from server');
      }

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid data format received');
      }

      print('✅ Parsing OverallReport...');

      return OverallReport.fromJson(data);
    } on ApiException catch (e) {
      print('❌ API Exception: ${e.message}');
      throw Exception('API Error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error fetching overall report: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Failed to fetch overall report: $e');
    }
  }

  /// Get overall monthly report for all students (or filtered by college)
  static Future<OverallMonthlyReport> getOverallMonthlyReport({
    required int year,
    required int month,
    String? collegeName,
  }) async {
    try {
      print(
          '🔍 Fetching overall monthly report (Year: $year, Month: $month, College: ${collegeName ?? "All"})');

      final Map<String, String> queryParams = {
        'year': year.toString(),
        'month': month.toString(),
      };

      if (collegeName != null && collegeName.isNotEmpty) {
        queryParams['college_name'] = collegeName;
      }

      final response = await ApiService.get(
        ApiConfig.reportsOverallMonthly,
        queryParams: queryParams,
      );

      // Debug logging
      print('📦 Overall Monthly Report Response: ${jsonEncode(response)}');

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Request failed');
      }

      if (response['data'] == null) {
        throw Exception('No data returned from server');
      }

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid data format received');
      }

      print('✅ Parsing OverallMonthlyReport...');

      return OverallMonthlyReport.fromJson(data);
    } on ApiException catch (e) {
      print('❌ API Exception: ${e.message}');
      throw Exception('API Error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error fetching overall monthly report: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Failed to fetch overall monthly report: $e');
    }
  }

  /// Get college-specific attendance report
  /// This endpoint returns the same structure as overall monthly report but filtered by college
  static Future<OverallMonthlyReport> getCollegeReport({
    required String collegeName,
    required int year,
    required int month,
  }) async {
    try {
      print(
          '🔍 Fetching college report for: $collegeName (Year: $year, Month: $month)');

      final response = await ApiService.get(
        '${ApiConfig.reportsCollege}/${Uri.encodeComponent(collegeName)}',
        queryParams: {
          'year': year.toString(),
          'month': month.toString(),
        },
      );

      // Debug logging
      print('📦 College Report Response: ${jsonEncode(response)}');

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Request failed');
      }

      if (response['data'] == null) {
        throw Exception('No data returned from server');
      }

      final data = response['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid data format received');
      }

      print('✅ Parsing College Report as OverallMonthlyReport...');

      // Reuse OverallMonthlyReport model since structure is the same
      return OverallMonthlyReport.fromJson(data);
    } on ApiException catch (e) {
      print('❌ API Exception: ${e.message}');
      throw Exception('API Error: ${e.message}');
    } catch (e, stackTrace) {
      print('❌ Error fetching college report: $e');
      print('📍 Stack trace: $stackTrace');
      throw Exception('Failed to fetch college report: $e');
    }
  }

  /// Get monthly report with default current month/year
  static Future<MonthlyReport> getCurrentMonthlyReport({
    required String studentIdNo,
  }) async {
    final now = DateTime.now();
    return getMonthlyReport(
      studentIdNo: studentIdNo,
      year: now.year,
      month: now.month,
    );
  }

  /// Get overall monthly report for current month
  static Future<OverallMonthlyReport> getCurrentOverallMonthlyReport({
    String? collegeName,
  }) async {
    final now = DateTime.now();
    return getOverallMonthlyReport(
      year: now.year,
      month: now.month,
      collegeName: collegeName,
    );
  }

  /// Get college report for current month
  static Future<OverallMonthlyReport> getCurrentCollegeReport({
    required String collegeName,
  }) async {
    final now = DateTime.now();
    return getCollegeReport(
      collegeName: collegeName,
      year: now.year,
      month: now.month,
    );
  }
}
