import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/cards/attendance_card.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  final Student student;

  const AttendanceHistoryScreen({super.key, required this.student});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    await context.read<AttendanceProvider>().fetchStudentAttendance(
          studentIdNo: widget.student.idNo,
          month: _selectedMonth,
          year: _selectedYear,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Attendance History',
      ),
      body: Consumer<AttendanceProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const LoadingWidget(message: 'Loading attendance...');
          }

          if (provider.error != null) {
            return CustomErrorWidget(
              message: provider.error!,
              onRetry: _loadAttendance,
            );
          }

          return Column(
            children: [
              // Student Info
              Container(
                padding: const EdgeInsets.all(16),
                color: AppTheme.surfaceVariant,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primary.withOpacity(0.1),
                      child: Text(
                        widget.student.initials,
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
                            widget.student.studentName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            widget.student.idNo,
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

              // Filters
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
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
                            _selectedYear = value;
                          });
                          _loadAttendance();
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
                            _selectedMonth = value;
                          });
                          _loadAttendance();
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Records List
              Expanded(
                child: provider.attendanceHistory.isEmpty
                    ? const EmptyState(
                        title: 'No Records Found',
                        message:
                            'No attendance records for the selected period',
                        icon: Icons.event_busy,
                      )
                    : RefreshIndicator(
                        onRefresh: _loadAttendance,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.attendanceHistory.length,
                          itemBuilder: (context, index) {
                            final attendance =
                                provider.attendanceHistory[index];
                            return AttendanceCard(attendance: attendance);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
