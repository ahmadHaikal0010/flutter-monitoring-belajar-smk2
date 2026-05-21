class ProgressModel {
  final int totalMaterials;
  final int completedMaterials;
  final int percentage;
  final List<String> completedMaterialIds;

  ProgressModel({
    required this.totalMaterials,
    required this.completedMaterials,
    required this.percentage,
    required this.completedMaterialIds,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      totalMaterials: json['total_materials'] ?? 0,
      completedMaterials: json['completed_materials'] ?? 0,
      percentage: json['percentage'] ?? 0,
      completedMaterialIds: List<String>.from(json['completed_material_ids'] ?? []),
    );
  }

  bool isMaterialCompleted(String materialId) {
    return completedMaterialIds.contains(materialId);
  }
}
