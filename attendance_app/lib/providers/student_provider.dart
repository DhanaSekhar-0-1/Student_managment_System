import 'package:flutter/material.dart';
import '../models/student.dart';
import '../models/college.dart';
import '../services/student_service.dart';

class StudentProvider with ChangeNotifier {
  // State
  List<Student> _students = [];
  List<College> _colleges = [];
  Student? _selectedStudent;
  String? _selectedCollege;
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  // Getters
  List<Student> get students => _students;
  List<College> get colleges => _colleges;
  Student? get selectedStudent => _selectedStudent;
  String? get selectedCollege => _selectedCollege;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Filtered students based on search and college
  List<Student> get filteredStudents {
    var filtered = _students;

    if (_selectedCollege != null && _selectedCollege!.isNotEmpty) {
      filtered = filtered
          .where((s) => s.collegeName == _selectedCollege)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((s) {
        return s.studentName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.pinNo.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            s.idNo.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  // Active students count
  int get activeStudentsCount =>
      _students.where((s) => s.isActive).length;

  // Inactive students count
  int get inactiveStudentsCount =>
      _students.where((s) => !s.isActive).length;

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // Set selected college
  void setSelectedCollege(String? college) {
    _selectedCollege = college;
    notifyListeners();
  }

  // Set selected student
  void setSelectedStudent(Student? student) {
    _selectedStudent = student;
    notifyListeners();
  }

  // Fetch all students
  Future<void> fetchStudents({
    int page = 1,
    int limit = 100,
    String? collegeName,
    int? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _students = await StudentService.getStudents(
        page: page,
        limit: limit,
        collegeName: collegeName,
        isActive: isActive,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch student by ID
  Future<Student?> fetchStudentById(String idNo) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final student = await StudentService.getStudentById(idNo);
      _selectedStudent = student;
      _error = null;
      _isLoading = false;
      notifyListeners();
      return student;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Fetch colleges
  Future<void> fetchColleges() async {
    try {
      _colleges = await StudentService.getColleges();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create student
  Future<bool> createStudent(Map<String, dynamic> studentData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final student = await StudentService.createStudent(studentData);
      _students.insert(0, student);
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update student
  Future<bool> updateStudent(String idNo, Map<String, dynamic> updateData) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedStudent = await StudentService.updateStudent(idNo, updateData);
      
      final index = _students.indexWhere((s) => s.idNo == idNo);
      if (index != -1) {
        _students[index] = updatedStudent;
      }
      
      if (_selectedStudent?.idNo == idNo) {
        _selectedStudent = updatedStudent;
      }
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Deactivate student
  Future<bool> deactivateStudent(String idNo) async {
    try {
      final student = await StudentService.deactivateStudent(idNo);
      
      final index = _students.indexWhere((s) => s.idNo == idNo);
      if (index != -1) {
        _students[index] = student;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Activate student
  Future<bool> activateStudent(String idNo) async {
    try {
      final student = await StudentService.activateStudent(idNo);
      
      final index = _students.indexWhere((s) => s.idNo == idNo);
      if (index != -1) {
        _students[index] = student;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset
  void reset() {
    _students = [];
    _colleges = [];
    _selectedStudent = null;
    _selectedCollege = null;
    _isLoading = false;
    _error = null;
    _searchQuery = '';
    notifyListeners();
  }
}