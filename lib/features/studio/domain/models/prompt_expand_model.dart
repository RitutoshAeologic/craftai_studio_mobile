import 'structured_prompt_metadata.dart';

class PromptExpandModel {
  final String masterPrompt;
  final String negativePrompt;
  final String modelUsed;
  final int complexityScore;
  final StructuredPromptMetadata? structuredMetadata;

  const PromptExpandModel({
    required this.masterPrompt,
    required this.negativePrompt,
    required this.modelUsed,
    this.complexityScore = 1,
    this.structuredMetadata,
  });

  factory PromptExpandModel.fromJson(Map<String, dynamic> json) {
    return PromptExpandModel(
      masterPrompt: json['master_prompt'] as String? ?? '',
      negativePrompt: json['negative_prompt'] as String? ?? '',
      modelUsed: json['model_used'] as String? ?? 'gemini-2.5-flash',
      complexityScore: (json['complexity_score'] as num?)?.toInt() ?? 1,
      structuredMetadata: json['structured_metadata'] != null
          ? StructuredPromptMetadata.fromJson(json['structured_metadata'] as Map<String, dynamic>?)
          : null,
    );
  }
}
