class SubjectModel {
  final String id;
  final String title;
  final String code;
  final String? description;
  final String teacherName;
  final String status;
  final DateTime enrolledAt;
  final bool isEnrolled;

  SubjectModel({
    required this.id,
    required this.title,
    required this.code,
    this.description,
    required this.teacherName,
    required this.status,
    required this.enrolledAt,
    this.isEnrolled = false,
  });

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] ?? '',
      title: json['title'] ?? 'Tanpa Judul',
      code: json['code'] ?? '-', // Aggregator mungkin tidak kirim code
      description: json['description'],
      teacherName: json['teacher_name'] ?? 'Guru',
      status: json['status'] ?? 'enrolled',
      enrolledAt: json['enrolled_at'] != null 
          ? DateTime.parse(json['enrolled_at']) 
          : (json['terdaftar_pada'] != null ? DateTime.parse(json['terdaftar_pada']) : DateTime.now()),
      isEnrolled: json['is_enrolled'] ?? false,
    );
  }
}
