class SubjectModel {
  final String id;
  final String title;
  final String code;
  final String? description;
  final String teacherName;
  final String status;
  final DateTime enrolledAt;

  SubjectModel({
    required this.id,
    required this.title,
    required this.code,
    this.description,
    required this.teacherName,
    required this.status,
    required this.enrolledAt,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'],
      title: json['title'],
      code: json['code'],
      description: json['description'],
      teacherName: json['teacher_name'],
      status: json['status'],
      enrolledAt: DateTime.parse(json['enrolled_at']),
    );
  }
}
