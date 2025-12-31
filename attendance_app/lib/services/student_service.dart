import '../models/student.dart';
import '../models/college.dart';
import 'api_service.dart';

class StudentService {
  static Future<List<Student>> getStudents({
    int page = 1,
    int limit = 20,
    String? collegeName,
    int? isActive,
    String? search,
  }) async {
    String endpoint = '/students?page=$page&limit=$limit';

    if (collegeName != null && collegeName.isNotEmpty) {
      endpoint += '&college_name=${Uri.encodeComponent(collegeName)}';
    }
    if (isActive != null) {
      endpoint += '&is_active=$isActive';
    }
    if (search != null && search.isNotEmpty) {
      endpoint += '&search=${Uri.encodeComponent(search)}';
    }

    final response = await ApiService.get(endpoint);

    final List<dynamic> studentsJson = response['data']['students'];
    return studentsJson.map((json) => Student.fromJson(json)).toList();
  }

  static Future<Student> getStudentById(String idNo) async {
    final response = await ApiService.get('/students/$idNo');
    return Student.fromJson(response['data']['student']);
  }

  static Future<Student> getStudentByNfc(String nfcId) async {
    final response = await ApiService.get('/students/by-nfc/$nfcId');
    return Student.fromJson(response['data']['student']);
  }

  static Future<List<College>> getColleges() async {
    final response = await ApiService.get('/students/colleges');
    final List<dynamic> collegesJson = response['data']['colleges'];
    return collegesJson.map((json) => College.fromJson(json)).toList();
  }

  static Future<Student> createStudent(Map<String, dynamic> studentData) async {
    final response = await ApiService.post('/students', studentData);
    return Student.fromJson(response['data']['student']);
  }

  static Future<Student> updateStudent(
    String idNo,
    Map<String, dynamic> updateData,
  ) async {
    final response = await ApiService.patch('/students/$idNo', updateData);
    return Student.fromJson(response['data']['student']);
  }

  static Future<Student> deactivateStudent(String idNo) async {
    final response = await ApiService.patch('/students/$idNo/deactivate', {});
    return Student.fromJson(response['data']['student']);
  }

  static Future<Student> activateStudent(String idNo) async {
    final response = await ApiService.patch('/students/$idNo/activate', {});
    return Student.fromJson(response['data']['student']);
  }
}
