import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/overall_monthly_report.dart';
import '../../services/report_service.dart';
import '../../providers/student_provider.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';

class OverallAttendanceReportScreen extends StatefulWidget {
  const OverallAttendanceReportScreen({super.key});

  @override
  State<OverallAttendanceReportScreen> createState() =>
      _OverallAttendanceReportScreenState();
}

class _OverallAttendanceReportScreenState
    extends State<OverallAttendanceReportScreen> {
  OverallMonthlyReport? _report;
  bool _isLoading = false;
  String? _error;
  String? _selectedCollege;

  final int currentYear = DateTime.now().year;
  final int currentMonth = DateTime.now().month;

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
        year: currentYear,
        month: currentMonth,
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
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          if (_isLoading) {
            return const LoadingWidget(message: 'Loading overall report...');
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // College Filter
                if (studentProvider.colleges.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filter by College',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilterChip(
                                label: const Text('All Colleges'),
                                selected: _selectedCollege == null,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCollege = null;
                                  });
                                  _loadReport();
                                },
                                selectedColor: AppTheme.primary,
                                labelStyle: TextStyle(
                                  color: _selectedCollege == null
                                      ? Colors.white
                                      : AppTheme.textPrimary,
                                ),
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
                                  selectedColor: AppTheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : AppTheme.textPrimary,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Header
                Card(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Month Report',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_report!.monthName} ${_report!.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        if (_selectedCollege != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'College: $_selectedCollege',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary Statistics',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 20),
                        _buildSummaryGrid(),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Students List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Student Details (${_report!.students.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Students List
                ..._report!.students.map((student) => _buildStudentCard(student)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryBox(
                label: 'Total Students',
                value: _report!.summary.totalStudents.toString(),
                icon: Icons.people,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryBox(
                label: 'Working Days',
                value: _report!.summary.totalWorkingDays.toString(),
                icon: Icons.calendar_month,
                color: AppTheme.info,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryBox(
                label: 'Overall Rate',
                value: _report!.summary.percentageText,
                icon: Icons.analytics,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryBox(
                label: 'Total Present',
                value: _report!.summary.totalPresent.toString(),
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
              child: _buildSummaryBox(
                label: 'Above 75%',
                value: _report!.summary.studentsAbove75.toString(),
                icon: Icons.trending_up,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryBox(
                label: 'Below 75%',
                value: _report!.summary.studentsBelow75.toString(),
                icon: Icons.trending_down,
                color: AppTheme.error,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryBox({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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

  Widget _buildStudentCard(StudentMonthlyData student) {
    Color statusColor;
    String statusText;

    if (student.status == 'GOOD') {
      statusColor = AppTheme.success;
      statusText = 'Good';
    } else if (student.status == 'NEEDS_IMPROVEMENT') {
      statusColor = AppTheme.warning;
      statusText = 'Needs Improvement';
    } else {
      statusColor = AppTheme.textTertiary;
      statusText = 'No Data';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    student.initials,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.studentName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        '${student.pinNo} • ${student.collegeName}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        student.percentageText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.calendar_month,
                    label: 'Days',
                    value: student.totalWorkingDays.toString(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.check_circle,
                    label: 'Present',
                    value: student.present.toString(),
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    icon: Icons.cancel,
                    label: 'Absent',
                    value: student.absent.toString(),
                    color: AppTheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color ?? AppTheme.textSecondary),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}