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
    final rawMeta = json['structured_metadata'];
    StructuredPromptMetadata? parsedMeta;
    if (rawMeta is Map) {
      parsedMeta = StructuredPromptMetadata.fromJson(Map<String, dynamic>.from(rawMeta));
    } else if (json['subject'] != null ||
        json['environment'] != null ||
        json['lighting'] != null ||
        json['camera'] != null ||
        json['camera_optics'] != null) {
      // Backward-compatible fallback when structured fields arrive at top level
      parsedMeta = StructuredPromptMetadata.fromJson(json);
    }

    final topNeg = json['negative_prompt'] as String?;
    final resolvedNeg = (topNeg != null && topNeg.isNotEmpty)
        ? topNeg
        : (parsedMeta?.negativePrompt ?? '');

    return PromptExpandModel(
      masterPrompt: json['master_prompt'] as String? ?? '',
      negativePrompt: resolvedNeg,
      modelUsed: json['model_used'] as String? ?? 'gemini-2.5-flash',
      complexityScore: (json['complexity_score'] as num?)?.toInt() ?? 1,
      structuredMetadata: parsedMeta,
    );
  }
}
