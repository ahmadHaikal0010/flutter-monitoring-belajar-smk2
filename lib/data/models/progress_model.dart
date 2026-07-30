class ExamProgressResultModel {
  final String examId;
  final String examTitle;
  final int duration;
  final int passScore;
  final String? sessionId;
  final String? sessionStatus;
  final double? totalScore;
  final bool? isPassed;
  final String? submittedAt;

  ExamProgressResultModel({
    required this.examId,
    required this.examTitle,
    required this.duration,
    required this.passScore,
    this.sessionId,
    this.sessionStatus,
    this.totalScore,
    this.isPassed,
    this.submittedAt,
  });

  factory ExamProgressResultModel.fromJson(Map<String, dynamic> json) {
    return ExamProgressResultModel(
      examId: json['exam_id'] ?? '',
      examTitle: json['exam_title'] ?? 'Ujian',
      duration: json['duration'] ?? 0,
      passScore: json['pass_score'] ?? 0,
      sessionId: json['session_id'],
      sessionStatus: json['session_status'],
      totalScore: json['total_score'] != null ? (json['total_score'] as num).toDouble() : null,
      isPassed: json['is_passed'],
      submittedAt: json['submitted_at'],
    );
  }
}

class ProgressModel {
  final int totalMaterials;
  final int completedMaterials;
  final int percentage;
  final List<String> completedMaterialIds;
  final List<ExamProgressResultModel> examResults;

  ProgressModel({
    required this.totalMaterials,
    required this.completedMaterials,
    required this.percentage,
    required this.completedMaterialIds,
    this.examResults = const [],
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      totalMaterials: json['total_materials'] ?? 0,
      completedMaterials: json['completed_materials'] ?? 0,
      percentage: json['percentage'] ?? 0,
      completedMaterialIds: List<String>.from(json['completed_material_ids'] ?? []),
      examResults: (json['exam_results'] as List?)
              ?.map((e) => ExamProgressResultModel.fromJson(e))
              .toList() ??
          [],
    );
  }

  bool isMaterialCompleted(String materialId) {
    return completedMaterialIds.contains(materialId);
  }
}
