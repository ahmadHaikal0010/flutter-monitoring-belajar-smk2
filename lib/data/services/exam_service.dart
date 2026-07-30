import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class ExamService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  Future<Response> getExams(String token, String subjectId) async {
    try {
      return await _dio.get(
        ApiConstants.subjectExams(subjectId),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> startExam(String token, String examId) async {
    try {
      return await _dio.post(
        ApiConstants.startExam(examId),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> submitAnswer(
    String token,
    String sessionId, {
    required String questionId,
    String? selectedOptionId,
    String? essayAnswer,
  }) async {
    try {
      final data = {
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
        'essay_answer': essayAnswer,
      };

      return await _dio.post(
        ApiConstants.submitAnswer(sessionId),
        data: data,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> submitAnswers(
    String token,
    String sessionId,
    List<Map<String, dynamic>> answers,
  ) async {
    try {
      return await _dio.post(
        ApiConstants.submitAnswers(sessionId),
        data: {'answers': answers},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> submitExam(String token, String sessionId) async {
    try {
      return await _dio.post(
        ApiConstants.submitExam(sessionId),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> getExamResult(String token, String sessionId) async {
    try {
      return await _dio.get(
        ApiConstants.examResult(sessionId),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }
}
