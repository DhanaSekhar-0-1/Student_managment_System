class DateUtils {
  // Get current date in API format
  static String getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Convert DateTime to API format
  static String toApiFormat(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Get month name
  static String getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // Get day name
  static String getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  // Check if working day (Monday-Saturday)
  static bool isWorkingDay(DateTime date) {
    return date.weekday != DateTime.sunday;
  }

  // Get first day of month
  static DateTime getFirstDayOfMonth(int year, int month) {
    return DateTime(year, month, 1);
  }

  // Get last day of month
  static DateTime getLastDayOfMonth(int year, int month) {
    return DateTime(year, month + 1, 0);
  }

  // Get date range for current month
  static Map<String, String> getCurrentMonthRange() {
    final now = DateTime.now();
    final firstDay = getFirstDayOfMonth(now.year, now.month);
    final lastDay = getLastDayOfMonth(now.year, now.month);
    
    return {
      'start_date': toApiFormat(firstDay),
      'end_date': toApiFormat(lastDay),
    };
  }
}