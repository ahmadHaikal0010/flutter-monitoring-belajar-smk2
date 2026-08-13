import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/subject_model.dart';
import '../../data/models/progress_model.dart';
import '../../data/models/recent_activity_model.dart';
import '../../data/services/enrollment_service.dart';
import '../../data/services/student_service.dart';
import '../../data/services/cache_service.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentService _enrollmentService = EnrollmentService();
  final StudentService _studentService = StudentService();
  
  List<SubjectModel> _subjects = [];
  final Map<String, ProgressModel> _subjectProgress = {}; // key: subjectId
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
    // 1. Instant Load from Cache
    await _loadDashboardFromCache();

    if (_subjects.isEmpty && _recentActivities.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      // 2. Fetch Fresh Data from API Server in Parallel
      final summaryFuture = _studentService.getDashboardSummary(token);
      final activityFuture = _studentService.getRecentActivities(token);
      final subjectFuture = _studentService.getEnrolledSubjectsWithProgress(token);

      final results = await Future.wait([summaryFuture, activityFuture, subjectFuture]);

      final summaryRes = results[0];
      final activityRes = results[1];
      final subjectRes = results[2];

      // Save & Update Summary
      if (summaryRes.data['success'] == true) {
        final data = summaryRes.data['data'];
        _summaryTotalSubjects = data['total_enrolled_subjects'];
        _summaryTotalCompleted = data['total_completed_materials'];
        _summaryOverallProgress = (data['overall_progress_percentage'] as num).toDouble();
        await CacheService.saveCache('dashboard_summary', data);
      }

      // Save & Update Activities
      if (activityRes.data['success'] == true) {
        final List data = activityRes.data['data'];
        _recentActivities = data.map((json) => RecentActivityModel.fromJson(json)).toList();
        await CacheService.saveCache('dashboard_activities', data);
      }

      // Save & Update Subjects
      if (subjectRes.data['success'] == true) {
        final List data = subjectRes.data['data'];
        _subjects = data.map((json) => SubjectModel.fromJson(json)).toList();
        await CacheService.saveCache('dashboard_subjects', data);
        
        // Fetch detailed progress including exam_results for all subjects
        await Future.wait(_subjects.map((subject) => fetchSubjectProgress(token, subject.id)));
      }

      _errorMessage = null;
    } catch (e) {
      debugPrint('Dashboard Fetch Error: $e');
      if (_subjects.isEmpty) {
        _errorMessage = 'Gagal memuat data. Periksa koneksi internet Anda.';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadDashboardFromCache() async {
    try {
      final summaryCache = await CacheService.getCache('dashboard_summary');
      if (summaryCache != null) {
        _summaryTotalSubjects = summaryCache['total_enrolled_subjects'] ?? 0;
        _summaryTotalCompleted = summaryCache['total_completed_materials'] ?? 0;
        _summaryOverallProgress = (summaryCache['overall_progress_percentage'] as num? ?? 0.0).toDouble();
      }

      final activityCache = await CacheService.getCache('dashboard_activities');
      if (activityCache != null && activityCache is List) {
        _recentActivities = activityCache.map((json) => RecentActivityModel.fromJson(json)).toList();
      }

      final subjectCache = await CacheService.getCache('dashboard_subjects');
      if (subjectCache != null && subjectCache is List) {
        _subjects = subjectCache.map((json) => SubjectModel.fromJson(json)).toList();
        for (final subject in _subjects) {
          final progressCache = await CacheService.getCache('subject_progress_${subject.id}');
          if (progressCache != null) {
            _subjectProgress[subject.id] = ProgressModel.fromJson(progressCache);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading dashboard cache: $e');
    }
  }

  // Fallback for screens that only need subjects
  Future<void> fetchEnrolledSubjects(String token) async {
    await fetchDashboardData(token);
  }

  Future<void> fetchSubjectProgress(String token, String subjectId) async {
    // Instant cache check
    final cached = await CacheService.getCache('subject_progress_$subjectId');
    if (cached != null) {
      _subjectProgress[subjectId] = ProgressModel.fromJson(cached);
      notifyListeners();
    }

    try {
      final response = await _studentService.getSubjectProgress(token, subjectId);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        _subjectProgress[subjectId] = ProgressModel.fromJson(data);
        await CacheService.saveCache('subject_progress_$subjectId', data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching progress for $subjectId: $e');
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
      debugPrint('Error marking material as completed: $e');
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
