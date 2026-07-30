import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../data/models/exam_model.dart';
import '../../data/models/exam_session_model.dart';
import '../../data/models/question_model.dart';
import '../../data/models/exam_result_model.dart';
import '../../data/services/exam_service.dart';

class ExamProvider with ChangeNotifier {
  final ExamService _examService = ExamService();
  
  List<ExamModel> _exams = [];
  ExamSessionModel? _currentSession;
  List<QuestionModel> _questions = [];
  Map<String, dynamic> _savedAnswers = {};
  ExamResultModel? _examResult;

  bool _isLoading = false;
  String? _errorMessage;

  List<ExamModel> get exams => _exams;
  ExamSessionModel? get currentSession => _currentSession;
  List<QuestionModel> get questions => _questions;
  Map<String, dynamic> get savedAnswers => _savedAnswers;
  ExamResultModel? get examResult => _examResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void clearExams() {
    _exams = [];
    notifyListeners();
  }

  Future<void> fetchExams(String token, String subjectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _examService.getExams(token, subjectId);
      if (response.data['success'] == true) {
        _exams = (response.data['data'] as List)
            .map((e) => ExamModel.fromJson(e))
            .toList();
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal memuat daftar ujian';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> startExam(String token, String examId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _examService.startExam(token, examId);
      if (response.data['success'] == true) {
        final data = response.data['data'];
        _currentSession = ExamSessionModel.fromJson(data['session']);
        _questions = (data['questions'] as List)
            .map((e) => QuestionModel.fromJson(e))
            .toList();
        
        // New Logic: Handle saved_answers as Dictionary { question_id: { data } }
        _savedAnswers = {};
        if (data['saved_answers'] is Map) {
          final Map saved = data['saved_answers'];
          saved.forEach((qId, val) {
            if (val is Map) {
              if (val['selected_option_id'] != null) {
                _savedAnswers[qId] = val['selected_option_id'];
              } else if (val['essay_answer'] != null) {
                _savedAnswers[qId] = val['essay_answer'];
              }
            }
          });
        }
        
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal memulai ujian';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> saveAnswer(String token, {
    required String questionId,
    String? selectedOptionId,
    String? essayAnswer,
  }) async {
    if (_currentSession == null) return;

    try {
      // Update local state immediately for snappy UI
      if (selectedOptionId != null) {
        _savedAnswers[questionId] = selectedOptionId;
      } else if (essayAnswer != null) {
        _savedAnswers[questionId] = essayAnswer;
      }
      notifyListeners();

      // Send to server real-time (instant save per question)
      await _examService.submitAnswer(
        token,
        _currentSession!.id,
        questionId: questionId,
        selectedOptionId: selectedOptionId,
        essayAnswer: essayAnswer,
      );
    } catch (e) {
      debugPrint('Gagal sinkronisasi jawaban real-time: $e');
    }
  }

  Future<void> syncAllAnswers(String token) async {
    if (_currentSession == null || _savedAnswers.isEmpty) return;

    try {
      List<Map<String, dynamic>> batchAnswers = [];
      _savedAnswers.forEach((qId, val) {
        final isEssay = _questions.any((q) => q.id == qId && q.questionType == 'essay');
        batchAnswers.add({
          'question_id': qId,
          'selected_option_id': isEssay ? null : val,
          'essay_answer': isEssay ? val : null,
        });
      });

      await _examService.submitAnswers(token, _currentSession!.id, batchAnswers);
    } catch (e) {
      debugPrint('Gagal sinkronisasi batch jawaban: $e');
    }
  }

  Future<bool> submitExam(String token) async {
    if (_currentSession == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Double check sync one last time before submitting
      await syncAllAnswers(token);

      final response = await _examService.submitExam(token, _currentSession!.id);
      if (response.data['success'] == true) {
        _currentSession = null;
        _questions = [];
        _savedAnswers = {};
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal mengumpulkan ujian';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> fetchExamResult(String token, String sessionId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _examService.getExamResult(token, sessionId);
      if (response.data['success'] == true) {
        _examResult = ExamResultModel.fromJson(response.data['data']);
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'Gagal memuat hasil ujian';
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan sistem';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
