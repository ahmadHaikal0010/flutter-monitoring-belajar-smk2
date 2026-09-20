import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class EnrollmentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  Future<Response> getEnrolledSubjects(String token) async {
    try {
      return await _dio.get(
        '/subjects',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> getAvailableSubjects(String token) async {
    try {
      return await _dio.get(
        '/subjects/available',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> enrollInSubject(String token, String subjectId) async {
    try {
      return await _dio.post(
        '/enroll',
        data: {'subject_id': subjectId},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> unenrollFromSubject(String token, String subjectId) async {
    try {
      return await _dio.delete(
        '/subjects/$subjectId/unenroll',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }
}
