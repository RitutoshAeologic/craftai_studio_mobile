class GenerationDispatchModel {
  final String taskId;
  final String tier;
  final String status;
  final String directImageUrl;

  const GenerationDispatchModel({
    required this.taskId,
    required this.tier,
    required this.status,
    required this.directImageUrl,
  });

  factory GenerationDispatchModel.fromJson(Map<String, dynamic> json) {
    return GenerationDispatchModel(
      taskId: json['task_id'] as String? ?? '',
      tier: json['tier'] as String? ?? 'Tier 0',
      status: json['status'] as String? ?? 'ready',
      directImageUrl: json['direct_image_url'] as String? ?? '',
    );
  }
}
