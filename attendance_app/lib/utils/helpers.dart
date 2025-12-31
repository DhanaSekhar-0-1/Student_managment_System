import 'package:intl/intl.dart';

class Helpers {
  // Format currency
  static String formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(2)}';
  }

  // Format date
  static String formatDate(DateTime date, {String format = 'dd MMM yyyy'}) {
    return DateFormat(format).format(date);
  }

  // Format time
  static String formatTime(String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time;
    }
  }

  // Get greeting based on time
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Validate mobile number
  static bool isValidMobile(String mobile) {
    return RegExp(r'^[0-9]{10}$').hasMatch(mobile);
  }

  // Validate NFC ID
  static bool isValidNfcId(String nfcId) {
    return nfcId.length == 16 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(nfcId);
  }

  // Get status color
  static String getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PRESENT':
        return '#10B981';
      case 'ABSENT':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  // Calculate percentage
  static double calculatePercentage(int part, int total) {
    if (total == 0) return 0;
    return (part / total) * 100;
  }

  // Format percentage
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }
}