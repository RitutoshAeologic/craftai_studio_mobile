import 'structured_prompt_metadata.dart';

class PromptCompileModel {
  final String compiledPrompt;
  final List<String> addedTags;
  final List<String> removedTags;
  final List<String> suggestedChips;
  final String modelUsed;
  final StructuredPromptMetadata? structuredMetadata;

  const PromptCompileModel({
    required this.compiledPrompt,
    required this.addedTags,
    required this.removedTags,
    required this.suggestedChips,
    required this.modelUsed,
    this.structuredMetadata,
  });

  factory PromptCompileModel.fromJson(Map<String, dynamic> json) {
    final diff = json['diff'] as Map<String, dynamic>? ?? {};
    return PromptCompileModel(
      compiledPrompt: json['compiled_prompt'] as String? ?? '',
      addedTags: List<String>.from(diff['added'] as List? ?? []),
      removedTags: List<String>.from(diff['removed'] as List? ?? []),
      suggestedChips: List<String>.from(json['suggested_chips'] as List? ?? []),
      modelUsed: json['model_used'] as String? ?? 'gemini-2.5-flash',
      structuredMetadata: json['structured_metadata'] != null
          ? StructuredPromptMetadata.fromJson(json['structured_metadata'] as Map<String, dynamic>?)
          : null,
    );
  }
}
