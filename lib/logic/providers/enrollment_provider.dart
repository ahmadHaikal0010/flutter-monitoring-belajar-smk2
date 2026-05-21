import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/progress_model.dart';
import '../../data/services/enrollment_service.dart';
import '../../data/services/student_service.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentService _enrollmentService = EnrollmentService();
  final StudentService _studentService = StudentService();
  
  List<SubjectModel> _subjects = [];
  Map<String, ProgressModel> _subjectProgress = {}; // key: subjectId
  bool _isLoading = false;
  String? _errorMessage;

  List<SubjectModel> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProgressModel? getProgress(String subjectId) => _subjectProgress[subjectId];

  Future<void> fetchEnrolledSubjects(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _enrollmentService.getEnrolledSubjects(token);
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        _subjects = data.map((json) => SubjectModel.fromJson(json)).toList();
        
        // Fetch progress for each subject
        for (var subject in _subjects) {
          await fetchSubjectProgress(token, subject.id);
        }
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal mengambil daftar mata pelajaran';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchSubjectProgress(String token, String subjectId) async {
    try {
      final response = await _studentService.getSubjectProgress(token, subjectId);
      if (response.data['success'] == true) {
        _subjectProgress[subjectId] = ProgressModel.fromJson(response.data['data']);
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching progress for $subjectId: $e');
    }
  }

  Future<bool> markAsCompleted(String token, String subjectId, String materialId) async {
    try {
      final response = await _studentService.markMaterialAsCompleted(token, materialId);
      if (response.data['success'] == true) {
        // Refresh progress for this subject
        await fetchSubjectProgress(token, subjectId);
        return true;
      }
    } catch (e) {
      print('Error marking material as completed: $e');
    }
    return false;
  }

  Future<bool> enroll(String token, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _enrollmentService.enrollInSubject(token, code);
      if (response.data['success'] == true) {
        await fetchEnrolledSubjects(token); // Refresh list and progress
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal mendaftar ke mata pelajaran';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }
}
