import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/student_provider.dart';
import 'student_reports_tab.dart';
import 'overall_monthly_report_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Fetch colleges when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchColleges();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(
              icon: Icon(Icons.person),
              text: 'Students',
            ),
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'Monthly',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Overall',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          StudentReportsTab(),
          OverallMonthlyReportScreen(),
          OverallAttendanceReportScreen(),
        ],
      ),
    );
  }
}

class OverallAttendanceReportScreen extends StatefulWidget {
  const OverallAttendanceReportScreen({super.key});

  @override
  State<OverallAttendanceReportScreen> createState() =>
      _OverallAttendanceReportScreenState();
}

class _OverallAttendanceReportScreenState
    extends State<OverallAttendanceReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Overall Attendance Report'),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Overall Attendance Report'),
      ),
    );
  }
}
