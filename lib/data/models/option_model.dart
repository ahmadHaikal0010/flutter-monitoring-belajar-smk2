class OptionModel {
  final String id;
  final String optionText;

  OptionModel({
    required this.id,
    required this.optionText,
  });

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'],
      optionText: json['option_text'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'option_text': optionText,
    };
  }
}
