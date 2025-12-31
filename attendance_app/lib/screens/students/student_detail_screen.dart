import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/cards/attendance_card.dart';
import '../reports/monthly_report_screen.dart';
import '../reports/overall_report_screen.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    final now = DateTime.now();
    await context.read<AttendanceProvider>().fetchStudentAttendance(
          studentIdNo: widget.student.idNo,
          month: now.month,
          year: now.year,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Student Details',
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 12),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: widget.student.isActive ? 'deactivate' : 'activate',
                child: Row(
                  children: [
                    Icon(
                      widget.student.isActive
                          ? Icons.person_off
                          : Icons.person_add,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(widget.student.isActive ? 'Deactivate' : 'Activate'),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'deactivate') {
                await _toggleStatus(false);
              } else if (value == 'activate') {
                await _toggleStatus(true);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      widget.student.initials,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.student.studentName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: widget.student.isActive
                          ? AppTheme.success
                          : AppTheme.error,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.student.statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Details Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student Information',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow(
                            label: 'Student ID',
                            value: widget.student.idNo,
                            icon: Icons.badge,
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'PIN Number',
                            value: widget.student.pinNo,
                            icon: Icons.pin,
                          ),
                          if (widget.student.nfcId != null) ...[
                            const Divider(),
                            _InfoRow(
                              label: 'NFC ID',
                              value: widget.student.nfcId!,
                              icon: Icons.nfc,
                            ),
                          ],
                          if (widget.student.collegeName != null) ...[
                            const Divider(),
                            _InfoRow(
                              label: 'College',
                              value: widget.student.collegeName!,
                              icon: Icons.school,
                            ),
                          ],
                          const Divider(),
                          _InfoRow(
                            label: 'Student Mobile',
                            value: widget.student.studentMobile,
                            icon: Icons.phone,
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'Parent Mobile',
                            value: widget.student.parentMobile,
                            icon: Icons.phone_android,
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'Fees Paid',
                            value: '₹${widget.student.feesPaid.toStringAsFixed(2)}',
                            icon: Icons.currency_rupee,
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'Enrolled On',
                            value: DateFormat('dd MMM yyyy')
                                .format(widget.student.createdAt),
                            icon: Icons.calendar_today,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'Monthly Report',
                          icon: Icons.calendar_month,
                          isOutlined: true,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MonthlyReportScreen(
                                  student: widget.student,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Overall Report',
                          icon: Icons.assessment,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OverallReportScreen(
                                  student: widget.student,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Recent Attendance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Attendance',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // View all attendance
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Consumer<AttendanceProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      if (provider.attendanceHistory.isEmpty) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No attendance records found',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.attendanceHistory.length > 5
                            ? 5
                            : provider.attendanceHistory.length,
                        itemBuilder: (context, index) {
                          final attendance = provider.attendanceHistory[index];
                          return AttendanceCard(attendance: attendance);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(bool activate) async {
    final provider = context.read<StudentProvider>();
    final success = activate
        ? await provider.activateStudent(widget.student.idNo)
        : await provider.deactivateStudent(widget.student.idNo);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            activate
                ? 'Student activated successfully'
                : 'Student deactivated successfully',
          ),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Operation failed'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied to clipboard'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}