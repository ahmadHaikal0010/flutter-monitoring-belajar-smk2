class ExamResultModel {
  final String id;
  final String examTitle;
  final double totalScore;
  final int passScore;
  final bool isPassed;
  final List<StudentAnswerResultModel> answers;

  ExamResultModel({
    required this.id,
    required this.examTitle,
    required this.totalScore,
    required this.passScore,
    required this.isPassed,
    required this.answers,
  });

  factory ExamResultModel.fromJson(Map<String, dynamic> json) {
    return ExamResultModel(
      id: json['id'],
      examTitle: json['exam_title'],
      totalScore: (json['total_score'] as num).toDouble(),
      passScore: json['pass_score'],
      isPassed: json['is_passed'],
      answers: (json['answers'] as List)
          .map((i) => StudentAnswerResultModel.fromJson(i))
          .toList(),
    );
  }
}

class StudentAnswerResultModel {
  final String questionId;
  final String questionText;
  final String questionType;
  final String? selectedOptionText;
  final String? essayAnswer;
  final bool? isCorrect;
  final double scoreEarned;
  final double maxScore;
  final String? materialId;
  final String? materialTitle;

  StudentAnswerResultModel({
    required this.questionId,
    required this.questionText,
    required this.questionType,
    this.selectedOptionText,
    this.essayAnswer,
    this.isCorrect,
    required this.scoreEarned,
    required this.maxScore,
    this.materialId,
    this.materialTitle,
  });

  factory StudentAnswerResultModel.fromJson(Map<String, dynamic> json) {
    return StudentAnswerResultModel(
      questionId: json['question_id'],
      questionText: json['question_text'],
      questionType: json['question_type'],
      selectedOptionText: json['selected_option_text'],
      essayAnswer: json['essay_answer'],
      isCorrect: json['is_correct'],
      scoreEarned: (json['score_earned'] as num).toDouble(),
      maxScore: (json['max_score'] as num).toDouble(),
      materialId: json['material_id'],
      materialTitle: json['material_title'],
    );
  }
}
