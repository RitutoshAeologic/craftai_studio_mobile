class PromptExpandModel {
  final String masterPrompt;
  final String negativePrompt;
  final String modelUsed;

  const PromptExpandModel({
    required this.masterPrompt,
    required this.negativePrompt,
    required this.modelUsed,
  });

  factory PromptExpandModel.fromJson(Map<String, dynamic> json) {
    return PromptExpandModel(
      masterPrompt: json['master_prompt'] as String? ?? '',
      negativePrompt: json['negative_prompt'] as String? ?? '',
      modelUsed: json['model_used'] as String? ?? 'gemini-1.5-flash',
    );
  }
}
