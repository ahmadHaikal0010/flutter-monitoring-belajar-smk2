import 'exam_session_model.dart';

class ExamModel {
  final String id;
  final String subjectId;
  final String title;
  final String? description;
  final int duration;
  final int passScore;
  final String? startTimeIso;
  final String? endTimeIso;
  final String? serverTimeIso;
  final String? timezoneOffset;
  final String? timezoneName;
  final int? questionCount;
  final ExamSessionModel? studentSession;

  DateTime? get startTime {
    if (startTimeIso == null) return null;
    try {
      return DateTime.parse(startTimeIso!.replaceAll(' ', 'T')).toLocal();
    } catch (_) {
      return null;
    }
  }

  DateTime? get endTime {
    if (endTimeIso == null) return null;
    try {
      return DateTime.parse(endTimeIso!.replaceAll(' ', 'T')).toLocal();
    } catch (_) {
      return null;
    }
  }

  ExamModel({
    required this.id,
    required this.subjectId,
    required this.title,
    this.description,
    required this.duration,
    required this.passScore,
    this.startTimeIso,
    this.endTimeIso,
    this.serverTimeIso,
    this.timezoneOffset,
    this.timezoneName,
    this.questionCount,
    this.studentSession,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'],
      subjectId: json['subject_id'],
      title: json['title'],
      description: json['description'],
      duration: json['duration'],
      passScore: json['pass_score'],
      startTimeIso: json['start_time_iso'],
      endTimeIso: json['end_time_iso'],
      serverTimeIso: json['server_time_iso'],
      timezoneOffset: json['timezone_offset'],
      timezoneName: json['timezone_name'],
      questionCount: json['question_count'],
      studentSession: json['student_session'] != null 
          ? ExamSessionModel.fromJson(json['student_session']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject_id': subjectId,
      'title': title,
      'description': description,
      'duration': duration,
      'pass_score': passScore,
      'start_time_iso': startTimeIso,
      'end_time_iso': endTimeIso,
      'server_time_iso': serverTimeIso,
      'timezone_offset': timezoneOffset,
      'timezone_name': timezoneName,
      'question_count': questionCount,
      'student_session': studentSession?.toJson(),
    };
  }
}
