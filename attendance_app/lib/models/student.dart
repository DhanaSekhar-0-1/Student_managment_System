class Student {
  final int sNo;
  final String studentName;
  final String pinNo;
  final String? nfcId;
  final String idNo;
  final String? collegeName;
  final String studentMobile;
  final String parentMobile;
  final double feesPaid;
  final bool isActive;
  final DateTime createdAt;

  Student({
    required this.sNo,
    required this.studentName,
    required this.pinNo,
    this.nfcId,
    required this.idNo,
    this.collegeName,
    required this.studentMobile,
    required this.parentMobile,
    required this.feesPaid,
    required this.isActive,
    required this.createdAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      sNo: _parseInt(json['S_No']),
      studentName: json['student_name'] as String,
      pinNo: json['pin_no'] as String,
      nfcId: json['nfc_id'] as String?,
      idNo: json['ID_No'] as String,
      collegeName: json['college_name'] as String?,
      studentMobile: json['student_mobile'] as String,
      parentMobile: json['parent_mobile'] as String,
      feesPaid: _parseDouble(json['fees_paid']),
      isActive: _parseBool(json['is_active']),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  // Helper methods for safe parsing
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> toJson() {
    return {
      'S_No': sNo,
      'student_name': studentName,
      'pin_no': pinNo,
      'nfc_id': nfcId,
      'ID_No': idNo,
      'college_name': collegeName,
      'student_mobile': studentMobile,
      'parent_mobile': parentMobile,
      'fees_paid': feesPaid,
      'is_active': isActive ? 1 : 0,
    };
  }

  // Helper getters
  String get displayName => studentName;
  String get displayId => idNo;
  String get statusText => isActive ? 'Active' : 'Inactive';
  
  // Get initials for avatar
  String get initials {
    final names = studentName.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return studentName.substring(0, 1).toUpperCase();
  }
}