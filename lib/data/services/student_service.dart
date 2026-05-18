import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class StudentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {
      'Accept': 'application/json',
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
    File? photo,
  }) async {
    try {
      // Menggunakan FormData untuk mendukung pengiriman file (Multipart)
      Map<String, dynamic> dataMap = {
        'name': name,
        'email': email,
        'nisn': nisn,
        'address': address,
      };

      if (photo != null) {
        String fileName = photo.path.split('/').last;
        dataMap['photo'] = await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
        );
      }

      FormData formData = FormData.fromMap(dataMap);

      final response = await _dio.post(
        ApiConstants.updateProfile,
        data: formData,
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
