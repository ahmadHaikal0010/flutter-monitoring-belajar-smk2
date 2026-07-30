import 'option_model.dart';

class QuestionModel {
  final String id;
  final String questionText;
  final String questionType;
  final String? imageUrl;
  final double score;
  final List<OptionModel> options;
  final String? materialId;
  final String? materialTitle;

  QuestionModel({
    required this.id,
    required this.questionText,
    required this.questionType,
    this.imageUrl,
    required this.score,
    required this.options,
    this.materialId,
    this.materialTitle,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      imageUrl: json['image_url'],
      score: (json['score'] as num).toDouble(),
      options: (json['options'] as List)
          .map((i) => OptionModel.fromJson(i))
          .toList(),
      materialId: json['material_id'],
      materialTitle: json['material_title'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': questionText,
      'question_type': questionType,
      'image_url': imageUrl,
      'score': score,
      'options': options.map((e) => e.toJson()).toList(),
      'material_id': materialId,
      'material_title': materialTitle,
    };
  }
}
