import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  Future<Response> login(String email, String password, String deviceName) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'device_name': deviceName,
        },
      );
      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> register({
    required String name,
    required String email,
    required String nisn,
    required String address,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.register,
        data: {
          'name': name,
          'email': email,
          'nisn': nisn,
          'address': address,
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return response;
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> logout(String token) async {
    try {
      final response = await _dio.post(
        ApiConstants.logout,
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

  Future<Response> getUserProfile(String token) async {
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
}
