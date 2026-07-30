class AssignmentSubmissionFileModel {
  final String id;
  final String filePath;
  final String fileName;
  final String fileType;

  AssignmentSubmissionFileModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileType,
  });

  factory AssignmentSubmissionFileModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionFileModel(
      id: json['id'] ?? '',
      filePath: json['file_path'] ?? '',
      fileName: json['file_name'] ?? 'File',
      fileType: json['file_type'] ?? 'image',
    );
  }
}

class AssignmentSubmissionModel {
  final String id;
  final String submittedAt;
  final String? notes;
  final double? score;
  final String? feedback;
  final String status;
  final List<AssignmentSubmissionFileModel> files;

  AssignmentSubmissionModel({
    required this.id,
    required this.submittedAt,
    this.notes,
    this.score,
    this.feedback,
    required this.status,
    this.files = const [],
  });

  factory AssignmentSubmissionModel.fromJson(Map<String, dynamic> json) {
    return AssignmentSubmissionModel(
      id: json['id'] ?? '',
      submittedAt: json['submitted_at'] ?? '',
      notes: json['notes'],
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      feedback: json['feedback'],
      status: json['status'] ?? 'submitted',
      files: (json['files'] as List?)
              ?.map((f) => AssignmentSubmissionFileModel.fromJson(f))
              .toList() ??
          [],
    );
  }
}

class AssignmentModel {
  final String id;
  final String subjectId;
  final String? subjectTitle;
  final String title;
  final String? description;
  final String? dueDate;
  final int maxScore;
  final List<String> allowedFileTypes;
  final AssignmentSubmissionModel? submission;

  AssignmentModel({
    required this.id,
    required this.subjectId,
    this.subjectTitle,
    required this.title,
    this.description,
    this.dueDate,
    required this.maxScore,
    this.allowedFileTypes = const [],
    this.submission,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] ?? '',
      subjectId: json['subject_id'] ?? '',
      subjectTitle: json['subject_title'],
      title: json['title'] ?? 'Tugas',
      description: json['description'],
      dueDate: json['due_date'],
      maxScore: json['max_score'] ?? 100,
      allowedFileTypes: List<String>.from(json['allowed_file_types'] ?? []),
      submission: json['submission'] != null
          ? AssignmentSubmissionModel.fromJson(json['submission'])
          : null,
    );
  }
}
