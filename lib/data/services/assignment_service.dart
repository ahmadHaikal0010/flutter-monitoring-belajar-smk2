import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';

class AssignmentService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    headers: {
      'Accept': 'application/json',
    },
  ));

  Future<Response> getSubjectAssignments(String token, String subjectId) async {
    try {
      return await _dio.get(
        '/subjects/$subjectId/assignments',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> getAssignmentDetail(String token, String assignmentId) async {
    try {
      return await _dio.get(
        '/assignments/$assignmentId',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }

  Future<Response> submitAssignment({
    required String token,
    required String assignmentId,
    String? notes,
    required List<File> files,
  }) async {
    try {
      final List<MultipartFile> multipartFiles = [];
      for (var file in files) {
        final fileName = file.path.split('/').last;
        multipartFiles.add(await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ));
      }

      final formData = FormData.fromMap({
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'files[]': multipartFiles,
      });

      return await _dio.post(
        '/assignments/$assignmentId/submit',
        data: formData,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } on DioException catch (_) {
      rethrow;
    }
  }
}
