import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/charts/monthly_bar_chart.dart';
import '../../widgets/charts/attendance_line_chart.dart';

class OverallReportScreen extends StatefulWidget {
  final Student student;

  const OverallReportScreen({super.key, required this.student});

  @override
  State<OverallReportScreen> createState() => _OverallReportScreenState();
}

class _OverallReportScreenState extends State<OverallReportScreen> {
  OverallReport? _report;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final report = await ReportService.getOverallReport(
        studentIdNo: widget.student.idNo,
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
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Overall Report'),
        body: LoadingWidget(message: 'Loading report...'),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Overall Report'),
        body: CustomErrorWidget(
          message: _error!,
          onRetry: _loadReport,
        ),
      );
    }

    if (_report == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Overall Report'),
        body: Center(
          child: Text('No report available'),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Overall Report'),
      body: RefreshIndicator(
        onRefresh: _loadReport,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Student Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.white,
                      child: Text(
                        _report!.student.initials,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
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
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _report!.student.idNo,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overall Summary
              Text(
                'Overall Summary',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Attendance Percentage
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppTheme.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _report!.overallSummary.percentageText,
                              style: Theme.of(context)
                                  .textTheme
                                  .displayLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.success,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Overall Attendance Rate',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Stats Grid
                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Working Days',
                              value: _report!.overallSummary.totalWorkingDays
                                  .toString(),
                              icon: Icons.calendar_month,
                              color: AppTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Present',
                              value: _report!.overallSummary.presentCount
                                  .toString(),
                              icon: Icons.check_circle,
                              color: AppTheme.success,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _StatBox(
                              label: 'Absent',
                              value: _report!.overallSummary.absentCount
                                  .toString(),
                              icon: Icons.cancel,
                              color: AppTheme.error,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatBox(
                              label: 'Days Enrolled',
                              value: _report!.overallSummary.daysEnrolled
                                  .toString(),
                              icon: Icons.event,
                              color: AppTheme.info,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Attendance Trend
              Text(
                'Attendance Trend',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Performance',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 16),
                      AttendanceLineChart(
                        percentages: _report!.monthlyBreakdown
                            .map((m) => m.percentage)
                            .toList(),
                        labels: _report!.monthlyBreakdown
                            .map((m) => m.monthName.substring(0, 3))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Monthly Breakdown
              Text(
                'Monthly Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      MonthlyBarChart(
                        data: _report!.monthlyBreakdown.reversed.toList(),
                      ),
                      const SizedBox(height: 20),
                      // Monthly Details
                      ..._report!.monthlyBreakdown.reversed.map((month) {
                        return _MonthlyItem(breakdown: month);
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
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

class _MonthlyItem extends StatelessWidget {
  final MonthlyBreakdown breakdown;

  const _MonthlyItem({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${breakdown.monthName} ${breakdown.year}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: breakdown.percentage >= 75
                      ? AppTheme.success.withOpacity(0.2)
                      : breakdown.percentage >= 50
                          ? AppTheme.warning.withOpacity(0.2)
                          : AppTheme.error.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  breakdown.percentageText,
                  style: TextStyle(
                    color: breakdown.percentage >= 75
                        ? AppTheme.success
                        : breakdown.percentage >= 50
                            ? AppTheme.warning
                            : AppTheme.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Present: ${breakdown.present}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.cancel,
                      size: 16,
                      color: AppTheme.error,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Absent: ${breakdown.absent}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: breakdown.percentage / 100,
              minHeight: 6,
              backgroundColor: AppTheme.outline,
              valueColor: AlwaysStoppedAnimation<Color>(
                breakdown.percentage >= 75
                    ? AppTheme.success
                    : breakdown.percentage >= 50
                        ? AppTheme.warning
                        : AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
