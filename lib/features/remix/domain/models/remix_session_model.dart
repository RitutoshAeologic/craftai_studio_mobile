import 'remix_message_model.dart';

class RemixSessionModel {
  final String id;
  final String? userId;
  final String anchorImageUrl;
  final String sourceType;
  final String? remixedFromPromptId;
  final String currentPrompt;
  final double styleWeight;
  final int turnCount;
  final String? lastGeneratedJobId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<RemixMessageModel> messages;

  const RemixSessionModel({
    required this.id,
    this.userId,
    required this.anchorImageUrl,
    required this.sourceType,
    this.remixedFromPromptId,
    required this.currentPrompt,
    required this.styleWeight,
    required this.turnCount,
    this.lastGeneratedJobId,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  factory RemixSessionModel.fromJson(Map<String, dynamic> json) {
    final sessionData = json.containsKey('session')
        ? json['session'] as Map<String, dynamic>
        : json;

    final rawMessages = json['messages'] as List? ?? [];
    final parsedMessages = rawMessages
        .map((m) => RemixMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    return RemixSessionModel(
      id: sessionData['id'] as String? ?? '',
      userId: sessionData['user_id'] as String?,
      anchorImageUrl: sessionData['anchor_image_url'] as String? ?? '',
      sourceType: sessionData['source_type'] as String? ?? 'explore',
      remixedFromPromptId: sessionData['remixed_from_prompt_id'] as String?,
      currentPrompt: sessionData['current_prompt'] as String? ?? '',
      styleWeight: (sessionData['style_weight'] as num?)?.toDouble() ?? 0.60,
      turnCount: sessionData['turn_count'] as int? ?? 0,
      lastGeneratedJobId: sessionData['last_generated_job_id'] as String?,
      createdAt: sessionData['created_at'] != null
          ? DateTime.tryParse(sessionData['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: sessionData['updated_at'] != null
          ? DateTime.tryParse(sessionData['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      messages: parsedMessages,
    );
  }

  RemixSessionModel copyWith({
    String? currentPrompt,
    double? styleWeight,
    int? turnCount,
    String? lastGeneratedJobId,
    List<RemixMessageModel>? messages,
  }) {
    return RemixSessionModel(
      id: id,
      userId: userId,
      anchorImageUrl: anchorImageUrl,
      sourceType: sourceType,
      remixedFromPromptId: remixedFromPromptId,
      currentPrompt: currentPrompt ?? this.currentPrompt,
      styleWeight: styleWeight ?? this.styleWeight,
      turnCount: turnCount ?? this.turnCount,
      lastGeneratedJobId: lastGeneratedJobId ?? this.lastGeneratedJobId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      messages: messages ?? this.messages,
    );
  }
}
