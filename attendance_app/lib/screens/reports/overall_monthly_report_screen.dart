// ignore_for_file: unused_import

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/report_service.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../models/overall_monthly_report.dart';

class OverallMonthlyReportScreen extends StatefulWidget {
  const OverallMonthlyReportScreen({super.key});

  @override
  State<OverallMonthlyReportScreen> createState() =>
      _OverallMonthlyReportScreenState();
}

class _OverallMonthlyReportScreenState
    extends State<OverallMonthlyReportScreen> {
  OverallMonthlyReport? _report;
  bool _isLoading = false;
  String? _error;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String? _selectedCollege;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await context.read<StudentProvider>().fetchColleges();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await ReportService.getOverallMonthlyReport(
        year: _selectedYear,
        month: _selectedMonth,
        collegeName: _selectedCollege,
      );

      if (!mounted) return;

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading report...');
    }

    if (_error != null) {
      return CustomErrorWidget(
        message: _error!,
        onRetry: _loadReport,
      );
    }

    if (_report == null) {
      return const Center(child: Text('No report available'));
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Month/Year & College Filter
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _selectedYear,
                                decoration: const InputDecoration(
                                  labelText: 'Year',
                                  prefixIcon: Icon(Icons.calendar_today),
                                ),
                                items: List.generate(5, (index) {
                                  final year = DateTime.now().year - index;
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedYear = value!;
                                  });
                                  _loadReport();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                initialValue: _selectedMonth,
                                decoration: const InputDecoration(
                                  labelText: 'Month',
                                  prefixIcon: Icon(Icons.event),
                                ),
                                items: List.generate(12, (index) {
                                  final monthNames = [
                                    'Jan',
                                    'Feb',
                                    'Mar',
                                    'Apr',
                                    'May',
                                    'Jun',
                                    'Jul',
                                    'Aug',
                                    'Sep',
                                    'Oct',
                                    'Nov',
                                    'Dec'
                                  ];
                                  return DropdownMenuItem(
                                    value: index + 1,
                                    child: Text(monthNames[index]),
                                  );
                                }),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMonth = value!;
                                  });
                                  _loadReport();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Filter by College',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedCollege == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCollege = null;
                                });
                                _loadReport();
                              },
                            ),
                            ...studentProvider.colleges.map((college) {
                              final isSelected =
                                  _selectedCollege == college.collegeName;
                              return FilterChip(
                                label: Text(college.collegeName),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCollege =
                                        selected ? college.collegeName : null;
                                  });
                                  _loadReport();
                                },
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_report!.monthName} ${_report!.year}',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryBox(
                                label: 'Students',
                                value:
                                    _report!.summary.totalStudents.toString(),
                                icon: Icons.people,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryBox(
                                label: 'Overall',
                                value: _report!.summary.percentageText,
                                icon: Icons.analytics,
                                color: AppTheme.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Students List
                Text(
                  'Students (${_report!.students.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                ..._report!.students.map((student) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(student.initials),
                      ),
                      title: Text(student.studentName),
                      subtitle: Text(student.collegeName),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: student.attendancePercentage >= 75
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          student.percentageText,
                          style: TextStyle(
                            color: student.attendancePercentage >= 75
                                ? AppTheme.success
                                : AppTheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class ReportService {
  static Future<OverallMonthlyReport> getOverallMonthlyReport({
    required int year,
    required int month,
    String? collegeName,
  }) async {
    try {
      // Call your API or database to fetch the report
      // Example (adjust based on your backend):
      final response = await http.get(
        Uri.parse(
          'your_api_endpoint/reports/overall-monthly'
          '?year=$year&month=$month'
          '${collegeName != null ? '&college=$collegeName' : ''}',
        ),
      );

      if (response.statusCode == 200) {
        return OverallMonthlyReport.fromJson(
          jsonDecode(response.body),
        );
      } else {
        throw Exception('Failed to load report');
      }
    } catch (e) {
      throw Exception('Error fetching report: $e');
    }
  }
}
