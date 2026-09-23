import 'remix_message_model.dart';

class RemixChatTurnResult {
  final String sessionId;
  final String compiledPrompt;
  final RemixMessageModel userMessage;
  final RemixMessageModel assistantMessage;
  final int turnCount;
  final List<String> suggestedChips;
  final String modelUsed;
  final int latencyMs;

  const RemixChatTurnResult({
    required this.sessionId,
    required this.compiledPrompt,
    required this.userMessage,
    required this.assistantMessage,
    required this.turnCount,
    required this.suggestedChips,
    required this.modelUsed,
    required this.latencyMs,
  });

  factory RemixChatTurnResult.fromJson(Map<String, dynamic> json) {
    return RemixChatTurnResult(
      sessionId: json['session_id'] as String? ?? '',
      compiledPrompt: json['compiled_prompt'] as String? ?? '',
      userMessage: RemixMessageModel.fromJson(json['user_message'] as Map<String, dynamic>? ?? {}),
      assistantMessage: RemixMessageModel.fromJson(json['assistant_message'] as Map<String, dynamic>? ?? {}),
      turnCount: json['turn_count'] as int? ?? 1,
      suggestedChips: List<String>.from(json['suggested_chips'] as List? ?? []),
      modelUsed: json['model_used'] as String? ?? 'groq',
      latencyMs: json['latency_ms'] as int? ?? 0,
    );
  }
}
