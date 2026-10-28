class JobModel {
  final String jobId;
  final String type;
  final String status;
  final String prompt;
  final String previewUrl;
  final String? masterUrl;
  final double creditsDeducted;
  final bool isDownloadUnlocked;
  final double downloadCost;
  final String toolApplied;
  final String aspectRatio;
  final String dimensions;
  final int seed;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  JobModel({
    required this.jobId,
    required this.type,
    required this.status,
    required this.prompt,
    required this.previewUrl,
    this.masterUrl,
    required this.creditsDeducted,
    this.isDownloadUnlocked = false,
    this.downloadCost = 2.0,
    this.toolApplied = 'text_to_image',
    this.aspectRatio = '1:1',
    this.dimensions = '1024x1024',
    this.seed = 42,
    this.metadata,
    required this.createdAt,
  });

  JobModel copyWith({
    bool? isDownloadUnlocked,
    String? toolApplied,
    String? aspectRatio,
    String? dimensions,
    int? seed,
    Map<String, dynamic>? metadata,
  }) {
    return JobModel(
      jobId: jobId,
      type: type,
      status: status,
      prompt: prompt,
      previewUrl: previewUrl,
      masterUrl: masterUrl,
      creditsDeducted: creditsDeducted,
      isDownloadUnlocked: isDownloadUnlocked ?? this.isDownloadUnlocked,
      downloadCost: downloadCost,
      toolApplied: toolApplied ?? this.toolApplied,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      dimensions: dimensions ?? this.dimensions,
      seed: seed ?? this.seed,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
    );
  }

  factory JobModel.fromJson(Map<String, dynamic> json) {
    return JobModel(
      jobId: (json['job_id'] ?? json['id'] ?? 'job_${DateTime.now().millisecondsSinceEpoch}').toString(),
      type: json['type'] as String? ?? 'IMAGE_GEN',
      status: json['status'] as String? ?? 'completed',
      prompt: json['prompt_text'] as String? ?? json['prompt'] as String? ?? '',
      previewUrl: json['preview_image_url'] as String? ?? json['preview_url'] as String? ?? '',
      masterUrl: json['master_image_url'] as String? ?? json['master_url'] as String?,
      creditsDeducted: (json['credits_deducted'] as num?)?.toDouble() ?? 2.0,
      isDownloadUnlocked: json['is_download_unlocked'] as bool? ?? false,
      downloadCost: (json['download_cost'] as num?)?.toDouble() ?? 2.0,
      toolApplied: json['tool_applied'] as String? ?? 'text_to_image',
      aspectRatio: json['aspect_ratio'] as String? ?? '1:1',
      dimensions: json['dimensions'] as String? ?? '1024x1024',
      seed: (json['seed'] as num?)?.toInt() ?? 42,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'job_id': jobId,
      'type': type,
      'status': status,
      'prompt': prompt,
      'prompt_text': prompt,
      'preview_url': previewUrl,
      'preview_image_url': previewUrl,
      'master_url': masterUrl,
      'master_image_url': masterUrl,
      'credits_deducted': creditsDeducted,
      'is_download_unlocked': isDownloadUnlocked,
      'download_cost': downloadCost,
      'tool_applied': toolApplied,
      'aspect_ratio': aspectRatio,
      'dimensions': dimensions,
      'seed': seed,
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

