class College {
  final String collegeName;
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;

  College({
    required this.collegeName,
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
  });

  factory College.fromJson(Map<String, dynamic> json) {
    return College(
      collegeName: json['college_name'] as String,
      // Parse string numbers to int safely
      totalStudents: _parseInt(json['total_students']),
      activeStudents: _parseInt(json['active_students']),
      inactiveStudents: _parseInt(json['inactive_students']),
    );
  }

  // Helper to safely parse int from dynamic value
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double get activePercentage => 
      totalStudents > 0 ? (activeStudents / totalStudents) * 100 : 0;

  String get activePercentageText => 
      '${activePercentage.toStringAsFixed(1)}%';
}