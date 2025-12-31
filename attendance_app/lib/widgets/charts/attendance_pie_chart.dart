import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../config/theme.dart';

class AttendancePieChart extends StatelessWidget {
  final int present;
  final int absent;
  final double size;

  const AttendancePieChart({
    super.key,
    required this.present,
    required this.absent,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final total = present + absent;
    
    if (total == 0) {
      return SizedBox(
        height: size,
        child: Center(
          child: Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
        ),
      );
    }

    return SizedBox(
      height: size,
      child: Row(
        children: [
          // Chart
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: size * 0.2,
                sections: [
                  PieChartSectionData(
                    value: present.toDouble(),
                    title: '${((present / total) * 100).toStringAsFixed(0)}%',
                    color: AppTheme.success,
                    radius: size * 0.25,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: absent.toDouble(),
                    title: '${((absent / total) * 100).toStringAsFixed(0)}%',
                    color: AppTheme.error,
                    radius: size * 0.25,
                    titleStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Legend
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: AppTheme.success,
                  label: 'Present',
                  value: present.toString(),
                ),
                const SizedBox(height: 12),
                _LegendItem(
                  color: AppTheme.error,
                  label: 'Absent',
                  value: absent.toString(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
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
              Text(
                value,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}