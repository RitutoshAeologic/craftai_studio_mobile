class CollectionItemModel {
  final String id;
  final String collectionId;
  final String? jobId;
  final String? explorePromptId;
  final String imageUrl;
  final String userId;
  final DateTime createdAt;

  CollectionItemModel({
    required this.id,
    required this.collectionId,
    this.jobId,
    this.explorePromptId,
    required this.imageUrl,
    required this.userId,
    required this.createdAt,
  });

  factory CollectionItemModel.fromJson(Map<String, dynamic> json) {
    return CollectionItemModel(
      id: (json['id'] ?? '').toString(),
      collectionId: (json['collection_id'] ?? '').toString(),
      jobId: json['job_id'] as String?,
      explorePromptId: json['explore_prompt_id'] as String?,
      imageUrl: (json['image_url'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection_id': collectionId,
      if (jobId != null) 'job_id': jobId,
      if (explorePromptId != null) 'explore_prompt_id': explorePromptId,
      'image_url': imageUrl,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
