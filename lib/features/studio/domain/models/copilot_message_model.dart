class CopilotMessage {
  final String id;
  final String text;
  final bool isUser;
  final List<String> addedTags;
  final List<String> removedTags;
  final DateTime timestamp;

  CopilotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    this.addedTags = const [],
    this.removedTags = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
