class MaterialModel {
  final String id;
  final String subjectId;
  final String title;
  final String contentType; // text, video, document, url
  final String contentBody;
  final String? contentBodyUrl; // Absolute URL for files
  final String? description;
  final DateTime createdAt;
  final String subjectTitle;

  MaterialModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.contentType,
    required this.contentBody,
    this.contentBodyUrl,
    this.description,
    required this.createdAt,
    required this.subjectTitle,
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    return MaterialModel(
      id: json['id'],
      subjectId: json['subject_id'],
      title: json['title'],
      contentType: json['content_type'],
      contentBody: json['content_body'],
      contentBodyUrl: json['content_body_url'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      subjectTitle: json['subject_title'],
    );
  }
}
