import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/subject_model.dart';
import '../../data/services/enrollment_service.dart';

class EnrollmentProvider with ChangeNotifier {
  final EnrollmentService _enrollmentService = EnrollmentService();
  
  List<SubjectModel> _subjects = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SubjectModel> get subjects => _subjects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchEnrolledSubjects(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _enrollmentService.getEnrolledSubjects(token);
      if (response.data['success'] == true) {
        final List data = response.data['data'];
        _subjects = data.map((json) => SubjectModel.fromJson(json)).toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal mengambil daftar mata pelajaran';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> enroll(String token, String code) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _enrollmentService.enrollInSubject(token, code);
      if (response.data['success'] == true) {
        await fetchEnrolledSubjects(token); // Refresh list
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
