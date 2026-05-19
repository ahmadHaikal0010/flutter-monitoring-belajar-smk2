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

  Future<Response> enrollInSubject(String token, String code) async {
    try {
      return await _dio.post(
        '/enroll',
        data: {'code': code},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }
}
