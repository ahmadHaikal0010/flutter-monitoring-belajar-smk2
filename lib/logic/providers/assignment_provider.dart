import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/assignment_model.dart';
import '../../data/services/assignment_service.dart';
import '../../data/services/cache_service.dart';

class AssignmentProvider with ChangeNotifier {
  final AssignmentService _assignmentService = AssignmentService();

  List<AssignmentModel> _assignments = [];
  AssignmentModel? _currentAssignment;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<AssignmentModel> get assignments => _assignments;
  AssignmentModel? get currentAssignment => _currentAssignment;
  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSubjectAssignments(String token, String subjectId) async {
    // 1. Instant Cache Load
    final cached = await CacheService.getCache('assignments_$subjectId');
    if (cached != null && cached is List) {
      _assignments = cached.map((json) => AssignmentModel.fromJson(json)).toList();
      notifyListeners();
    }

    if (_assignments.isEmpty) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _assignmentService.getSubjectAssignments(token, subjectId);
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        _assignments = data.map((json) => AssignmentModel.fromJson(json)).toList();
        await CacheService.saveCache('assignments_$subjectId', data);
        _errorMessage = null;
      }
    } on DioException catch (e) {
      if (_assignments.isEmpty) {
        _errorMessage = e.response?.data['message'] ?? 'Gagal memuat daftar tugas.';
      }
    } catch (e) {
      if (_assignments.isEmpty) {
        _errorMessage = 'Terjadi kesalahan sistem.';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAssignmentDetail(String token, String assignmentId) async {
    // 1. Instant Cache Load
    final cached = await CacheService.getCache('assignment_detail_$assignmentId');
    if (cached != null) {
      _currentAssignment = AssignmentModel.fromJson(cached);
      notifyListeners();
    }

    if (_currentAssignment == null) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final response = await _assignmentService.getAssignmentDetail(token, assignmentId);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        _currentAssignment = AssignmentModel.fromJson(data);
        await CacheService.saveCache('assignment_detail_$assignmentId', data);
        _errorMessage = null;
      }
    } on DioException catch (e) {
      if (_currentAssignment == null) {
        _errorMessage = e.response?.data['message'] ?? 'Gagal memuat detail tugas.';
      }
    } catch (e) {
      if (_currentAssignment == null) {
        _errorMessage = 'Terjadi kesalahan sistem.';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitAssignment(
    String token, {
    required String assignmentId,
    String? notes,
    required List<File> files,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _assignmentService.submitAssignment(
        token: token,
        assignmentId: assignmentId,
        notes: notes,
        files: files,
      );

      if (response.data['success'] == true) {
        // Refresh detail to show submitted state & update cache
        await fetchAssignmentDetail(token, assignmentId);
        _isSubmitting = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal mengumpulkan tugas.';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat mengunggah tugas.';
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }
}
