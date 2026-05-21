import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/progress_model.dart';
import '../../data/models/recent_activity_model.dart';
import '../../data/services/enrollment_service.dart';
import '../../data/services/student_service.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentService _enrollmentService = EnrollmentService();
  final StudentService _studentService = StudentService();
  
  List<SubjectModel> _subjects = [];
  Map<String, ProgressModel> _subjectProgress = {}; // key: subjectId
  List<RecentActivityModel> _recentActivities = [];
  
  // Dashboard Summary Data
  int _summaryTotalSubjects = 0;
  int _summaryTotalCompleted = 0;
  double _summaryOverallProgress = 0.0;

  bool _isLoading = false;
  String? _errorMessage;

  List<SubjectModel> get subjects => _subjects;
  List<RecentActivityModel> get recentActivities => _recentActivities;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ProgressModel? getProgress(String subjectId) => _subjectProgress[subjectId];

  // Dashboard Getters
  int get totalSubjects => _summaryTotalSubjects > 0 ? _summaryTotalSubjects : _subjects.length;
  int get totalCompletedMaterials => _summaryTotalCompleted;
  double get averageProgress => _summaryOverallProgress;

  Future<void> fetchDashboardData(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Summary
      final summaryRes = await _studentService.getDashboardSummary(token);
      if (summaryRes.data['success'] == true) {
        final data = summaryRes.data['data'];
        _summaryTotalSubjects = data['total_enrolled_subjects'];
        _summaryTotalCompleted = data['total_completed_materials'];
        _summaryOverallProgress = (data['overall_progress_percentage'] as num).toDouble();
      }

      // 2. Fetch Recent Activities
      final activityRes = await _studentService.getRecentActivities(token);
      if (activityRes.data['success'] == true) {
        final List data = activityRes.data['data'];
        _recentActivities = data.map((json) => RecentActivityModel.fromJson(json)).toList();
      }

      // 3. Fetch Subjects with Progress (Optimized)
      final subjectRes = await _studentService.getEnrolledSubjectsWithProgress(token);
      if (subjectRes.data['success'] == true) {
        final List data = subjectRes.data['data'];
        _subjects = data.map((json) => SubjectModel.fromJson(json)).toList();
        
        // Map progress data from the optimized response
        for (var json in data) {
          if (json['progress'] != null) {
            _subjectProgress[json['id']] = ProgressModel.fromJson(json['progress']);
          }
        }
      }
    } catch (e) {
      print('Dashboard Fetch Error: $e');
      _errorMessage = 'Gagal memuat data dashboard';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Fallback for screens that only need subjects
  Future<void> fetchEnrolledSubjects(String token) async {
    await fetchDashboardData(token);
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
        // Refresh everything to keep stats accurate
        await fetchDashboardData(token);
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
        await fetchDashboardData(token); // Refresh list and progress
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
