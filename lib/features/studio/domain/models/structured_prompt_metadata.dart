/// Visual Director structured breakdown extracted by Gemini / LLM expander.
/// Follows API_INTEGRATION_SPEC.md §2.4.1.
class StructuredPromptMetadata {
  final String subject;
  final String environment;
  final String lighting;
  final String cameraOptics;
  final String artStyle;
  final String negativePrompt;
  final List<String> avoid;
  final List<String> preservedElements;

  /// Alias matching backend `camera` key while keeping `cameraOptics` compatible.
  String get camera => cameraOptics;

  const StructuredPromptMetadata({
    this.subject = '',
    this.environment = '',
    this.lighting = '',
    this.cameraOptics = '',
    this.artStyle = '',
    this.negativePrompt = '',
    this.avoid = const [],
    this.preservedElements = const [],
  });

  factory StructuredPromptMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StructuredPromptMetadata();
    return StructuredPromptMetadata(
      subject: json['subject'] as String? ?? '',
      environment: json['environment'] as String? ?? '',
      lighting: json['lighting'] as String? ?? '',
      cameraOptics: (json['camera_optics'] ?? json['camera']) as String? ?? '',
      artStyle: json['art_style'] as String? ?? '',
      negativePrompt: json['negative_prompt'] as String? ?? '',
      avoid: List<String>.from(json['avoid'] as List? ?? []),
      preservedElements: List<String>.from(json['preserved_elements'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    if (subject.isNotEmpty) 'subject': subject,
    if (environment.isNotEmpty) 'environment': environment,
    if (lighting.isNotEmpty) 'lighting': lighting,
    if (cameraOptics.isNotEmpty) 'camera_optics': cameraOptics,
    if (cameraOptics.isNotEmpty) 'camera': cameraOptics,
    if (artStyle.isNotEmpty) 'art_style': artStyle,
    if (negativePrompt.isNotEmpty) 'negative_prompt': negativePrompt,
    if (avoid.isNotEmpty) 'avoid': avoid,
    if (preservedElements.isNotEmpty) 'preserved_elements': preservedElements,
  };

  bool get isEmpty =>
      subject.isEmpty &&
      environment.isEmpty &&
      lighting.isEmpty &&
      cameraOptics.isEmpty &&
      artStyle.isEmpty &&
      negativePrompt.isEmpty &&
      avoid.isEmpty &&
      preservedElements.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

