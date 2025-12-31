import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/charts/attendance_pie_chart.dart';
//import 'package:table_calendar/table_calendar.dart';

class MonthlyReportScreen extends StatefulWidget {
  final Student? student;

  const MonthlyReportScreen({super.key, this.student});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  MonthlyReport? _report;
  bool _isLoading = false;
  String? _error;

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _loadReport();
    }
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await ReportService.getMonthlyReport(
        studentIdNo: widget.student!.idNo,
        year: _selectedYear,
        month: _selectedMonth,
      );

      setState(() {
        _report = report;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.student == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Monthly Report'),
        body: Center(
          child: Text('Please select a student'),
        ),
      );
    }

    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Monthly Report'),
        body: LoadingWidget(message: 'Loading report...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Monthly Report'),
        body: CustomErrorWidget(
          message: _error!,
          onRetry: _loadReport,
        ),
      );
    }

    if (_report == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Monthly Report'),
        body: Center(
          child: Text('No report available'),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Monthly Report'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        _report!.student.initials,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _report!.student.studentName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            _report!.student.idNo,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Month/Year Selector
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
                        'January',
                        'February',
                        'March',
                        'April',
                        'May',
                        'June',
                        'July',
                        'August',
                        'September',
                        'October',
                        'November',
                        'December'
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

            const SizedBox(height: 24),

            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_report!.report.monthName} ${_report!.report.year}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    AttendancePieChart(
                      present: _report!.report.presentCount,
                      absent: _report!.report.absentCount,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _StatBox(
                            label: 'Working Days',
                            value: _report!.report.totalWorkingDays.toString(),
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatBox(
                            label: 'Attendance',
                            value: _report!.report.percentageText,
                            color: AppTheme.success,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Calendar View
            Text(
              'Daily Records',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: _report!.dailyRecords.map((record) {
                    return _DayRecord(record: record);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DayRecord extends StatelessWidget {
  final DailyRecord record;

  const _DayRecord({required this.record});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    if (record.isSunday) {
      statusColor = AppTheme.warning;
      statusIcon = Icons.event_busy;
    } else if (record.isPresent) {
      statusColor = AppTheme.success;
      statusIcon = Icons.check_circle;
    } else if (record.isAbsent) {
      statusColor = AppTheme.error;
      statusIcon = Icons.cancel;
    } else {
      statusColor = AppTheme.textTertiary;
      statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.day,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  DateFormat('dd MMM yyyy').format(DateTime.parse(record.date)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                record.status,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              if (record.time != null)
                Text(
                  record.time!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
