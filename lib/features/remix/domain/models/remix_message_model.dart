class RemixMessageModel {
  final String id;
  final String sessionId;
  final String role; // 'user' | 'assistant'
  final String content;
  final List<String> diffAdded;
  final List<String> diffRemoved;
  final List<String> suggestedChips;
  final String? generatedImageUrl;
  final String? modelUsed;
  final int? latencyMs;
  final DateTime createdAt;
  final bool isOptimistic;

  const RemixMessageModel({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    this.diffAdded = const [],
    this.diffRemoved = const [],
    this.suggestedChips = const [],
    this.generatedImageUrl,
    this.modelUsed,
    this.latencyMs,
    required this.createdAt,
    this.isOptimistic = false,
  });

  bool get isUser => role == 'user';

  factory RemixMessageModel.fromJson(Map<String, dynamic> json) {
    return RemixMessageModel(
      id: json['id'] as String? ?? 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: json['session_id'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      diffAdded: List<String>.from(json['diff_added'] as List? ?? []),
      diffRemoved: List<String>.from(json['diff_removed'] as List? ?? []),
      suggestedChips: List<String>.from(json['suggested_chips'] as List? ?? []),
      generatedImageUrl: json['generated_image_url'] as String?,
      modelUsed: json['model_used'] as String?,
      latencyMs: json['latency_ms'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      isOptimistic: false,
    );
  }

  RemixMessageModel copyWith({
    String? id,
    String? content,
    List<String>? diffAdded,
    List<String>? diffRemoved,
    List<String>? suggestedChips,
    String? generatedImageUrl,
    String? modelUsed,
    int? latencyMs,
    bool? isOptimistic,
  }) {
    return RemixMessageModel(
      id: id ?? this.id,
      sessionId: sessionId,
      role: role,
      content: content ?? this.content,
      diffAdded: diffAdded ?? this.diffAdded,
      diffRemoved: diffRemoved ?? this.diffRemoved,
      suggestedChips: suggestedChips ?? this.suggestedChips,
      generatedImageUrl: generatedImageUrl ?? this.generatedImageUrl,
      modelUsed: modelUsed ?? this.modelUsed,
      latencyMs: latencyMs ?? this.latencyMs,
      createdAt: createdAt,
      isOptimistic: isOptimistic ?? this.isOptimistic,
    );
  }
}
