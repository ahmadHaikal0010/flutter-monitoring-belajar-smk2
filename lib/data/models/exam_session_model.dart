class ExamSessionModel {
  final String id;
  final String examId;
  final String status;
  final String startedAtIso;
  final String? submittedAt;
  final double? totalScore;
  final int? duration; 
  final int? passScore;
  final String? serverTimeIso;
  final String? timezoneOffset;
  final int? remainingSeconds;
  final int? durationSeconds;
  final bool? isExpired;

  ExamSessionModel({
    required this.id,
    required this.examId,
    required this.status,
    required this.startedAtIso,
    this.submittedAt,
    this.totalScore,
    this.duration,
    this.passScore,
    this.serverTimeIso,
    this.timezoneOffset,
    this.remainingSeconds,
    this.durationSeconds,
    this.isExpired,
  });

  factory ExamSessionModel.fromJson(Map<String, dynamic> json) {
    return ExamSessionModel(
      id: json['id'],
      examId: json['exam_id'],
      status: json['status'],
      startedAtIso: json['started_at_iso'] ?? '',
      submittedAt: json['submitted_at'],
      totalScore: json['total_score']?.toDouble(),
      duration: json['duration'],
      passScore: json['pass_score'],
      serverTimeIso: json['server_time_iso'],
      timezoneOffset: json['timezone_offset'],
      remainingSeconds: json['remaining_seconds'],
      durationSeconds: json['duration_seconds'],
      isExpired: json['is_expired'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'exam_id': examId,
      'status': status,
      'started_at_iso': startedAtIso,
      'submitted_at': submittedAt,
      'total_score': totalScore,
      'duration': duration,
      'pass_score': passScore,
      'server_time_iso': serverTimeIso,
      'timezone_offset': timezoneOffset,
      'remaining_seconds': remainingSeconds,
      'duration_seconds': durationSeconds,
      'is_expired': isExpired,
    };
  }
}
