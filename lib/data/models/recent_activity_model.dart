class RecentActivityModel {
  final String materialId;
  final String materialTitle;
  final String subjectTitle;
  final DateTime lastAccessed;

  RecentActivityModel({
    required this.materialId,
    required this.materialTitle,
    required this.subjectTitle,
    required this.lastAccessed,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      materialId: json['material_id'] ?? '',
      materialTitle: json['material_title'] ?? 'Materi',
      subjectTitle: json['subject_title'] ?? 'Mata Pelajaran',
      lastAccessed: json['last_accessed'] != null 
          ? DateTime.parse(json['last_accessed']) 
          : DateTime.now(),
    );
  }
}
