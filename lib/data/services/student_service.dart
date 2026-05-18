import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class StudentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  Future<Response> getProfile(String token) async {
    try {
      final response = await _dio.get(
        ApiConstants.profile,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> updateProfile({
    required String token,
    required String name,
    required String email,
    String? nisn,
    String? address,
    // Note: Photo update usually needs MultipartFile
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.updateProfile,
        data: {
          'name': name,
          'email': email,
          'nisn': nisn,
          'address': address,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }
}
