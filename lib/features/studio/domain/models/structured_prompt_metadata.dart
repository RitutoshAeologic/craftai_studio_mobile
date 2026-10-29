/// Visual Director structured breakdown extracted by Gemini / LLM expander.
/// Follows API_INTEGRATION_SPEC.md §2.4.1.
class StructuredPromptMetadata {
  final String subject;
  final String environment;
  final String lighting;
  final String cameraOptics;
  final String artStyle;
  final List<String> avoid;
  final List<String> preservedElements;

  const StructuredPromptMetadata({
    this.subject = '',
    this.environment = '',
    this.lighting = '',
    this.cameraOptics = '',
    this.artStyle = '',
    this.avoid = const [],
    this.preservedElements = const [],
  });

  factory StructuredPromptMetadata.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const StructuredPromptMetadata();
    return StructuredPromptMetadata(
      subject: json['subject'] as String? ?? '',
      environment: json['environment'] as String? ?? '',
      lighting: json['lighting'] as String? ?? '',
      cameraOptics: json['camera_optics'] as String? ?? '',
      artStyle: json['art_style'] as String? ?? '',
      avoid: List<String>.from(json['avoid'] as List? ?? []),
      preservedElements: List<String>.from(json['preserved_elements'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
    if (subject.isNotEmpty) 'subject': subject,
    if (environment.isNotEmpty) 'environment': environment,
    if (lighting.isNotEmpty) 'lighting': lighting,
    if (cameraOptics.isNotEmpty) 'camera_optics': cameraOptics,
    if (artStyle.isNotEmpty) 'art_style': artStyle,
    if (avoid.isNotEmpty) 'avoid': avoid,
    if (preservedElements.isNotEmpty) 'preserved_elements': preservedElements,
  };

  bool get isEmpty =>
      subject.isEmpty &&
      environment.isEmpty &&
      lighting.isEmpty &&
      cameraOptics.isEmpty &&
      artStyle.isEmpty &&
      avoid.isEmpty &&
      preservedElements.isEmpty;

  bool get isNotEmpty => !isEmpty;
}

