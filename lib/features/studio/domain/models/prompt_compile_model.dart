class PromptCompileModel {
  final String compiledPrompt;
  final List<String> addedTags;
  final List<String> removedTags;
  final List<String> suggestedChips;
  final String modelUsed;

  const PromptCompileModel({
    required this.compiledPrompt,
    required this.addedTags,
    required this.removedTags,
    required this.suggestedChips,
    required this.modelUsed,
  });

  factory PromptCompileModel.fromJson(Map<String, dynamic> json) {
    final diff = json['diff'] as Map<String, dynamic>? ?? {};
    return PromptCompileModel(
      compiledPrompt: json['compiled_prompt'] as String? ?? '',
      addedTags: List<String>.from(diff['added'] as List? ?? []),
      removedTags: List<String>.from(diff['removed'] as List? ?? []),
      suggestedChips: List<String>.from(json['suggested_chips'] as List? ?? []),
      modelUsed: json['model_used'] as String? ?? 'gemini-1.5-flash',
    );
  }
}
