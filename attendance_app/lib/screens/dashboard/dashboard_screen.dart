import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/student_provider.dart';
import '../../providers/attendance_provider.dart';
import '../../widgets/common/custom_app_bar.dart';
import '../../widgets/common/loading_widget.dart';
import '../../widgets/common/error_widget.dart';
import '../../widgets/cards/stat_card.dart';
import '../../widgets/cards/college_card.dart';
import '../../widgets/charts/attendance_pie_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final studentProvider = context.read<StudentProvider>();
    final attendanceProvider = context.read<AttendanceProvider>();

    await Future.wait([
      studentProvider.fetchStudents(),
      studentProvider.fetchColleges(),
      attendanceProvider.fetchTodayAttendance(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Dashboard',
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: Consumer2<StudentProvider, AttendanceProvider>(
          builder: (context, studentProvider, attendanceProvider, child) {
            if (studentProvider.isLoading || attendanceProvider.isLoading) {
              return const LoadingWidget(message: 'Loading dashboard...');
            }

            if (studentProvider.error != null) {
              return CustomErrorWidget(
                message: studentProvider.error!,
                onRetry: _loadData,
              );
            }

            final todayAttendance = attendanceProvider.todayAttendance;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    'Welcome Back! 👋',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Here\'s what\'s happening today',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Stats
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      StatCard(
                        title: 'Total Students',
                        value: studentProvider.students.length.toString(),
                        icon: Icons.people,
                        color: AppTheme.primary,
                        useGradient: true,
                      ),
                      StatCard(
                        title: 'Active Students',
                        value: studentProvider.activeStudentsCount.toString(),
                        icon: Icons.check_circle,
                        color: AppTheme.success,
                      ),
                      StatCard(
                        title: 'Present Today',
                        value:
                            todayAttendance?.summary.present.toString() ?? '0',
                        icon: Icons.how_to_reg,
                        color: AppTheme.success,
                      ),
                      StatCard(
                        title: 'Absent Today',
                        value:
                            todayAttendance?.summary.absent.toString() ?? '0',
                        icon: Icons.person_off,
                        color: AppTheme.error,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Today's Attendance Chart
                  if (todayAttendance != null) ...[
                    Text(
                      'Today\'s Attendance',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      todayAttendance.dayOfWeek,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    Text(
                                      todayAttendance.date,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                                if (todayAttendance.isHoliday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warning.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.event_busy,
                                          size: 16,
                                          color: AppTheme.warning,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Holiday',
                                          style: TextStyle(
                                            color: AppTheme.warning,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            AttendancePieChart(
                              present: todayAttendance.summary.present,
                              absent: todayAttendance.summary.absent,
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        todayAttendance.summary.total
                                            .toString(),
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        'Total',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 40,
                                    color: AppTheme.outline,
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        todayAttendance.summary.percentageText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.success,
                                            ),
                                      ),
                                      Text(
                                        'Attendance Rate',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Colleges List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Colleges',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to colleges screen
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: studentProvider.colleges.length,
                    itemBuilder: (context, index) {
                      final college = studentProvider.colleges[index];
                      return CollegeCard(
                        college: college,
                        onTap: () {
                          // Navigate to college details
                          studentProvider
                              .setSelectedCollege(college.collegeName);
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
