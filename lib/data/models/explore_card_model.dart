class ExploreCardModel {
  final String id;
  final String authorName;
  final String authorHandle;
  final String authorAvatar;
  final String title;
  final String previewUrl;
  final String category;
  final String maskedSummary;
  final double remixFee;
  final double creatorRoyaltyCut;
  final int remixCount;
  final int likeCount;
  final bool isLiked;
  final bool isBookmarked;

  final String modelUsed;
  final String toolApplied;
  final String aspectRatio;
  final String dimensions;
  final int seed;
  final double costCredits;
  final String fullPrompt;
  final String negativePrompt;
  final String createdAt;

  ExploreCardModel({
    required this.id,
    required this.authorName,
    required this.authorHandle,
    required this.authorAvatar,
    required this.title,
    required this.previewUrl,
    required this.category,
    required this.maskedSummary,
    required this.remixFee,
    required this.creatorRoyaltyCut,
    required this.remixCount,
    required this.likeCount,
    this.isLiked = false,
    this.isBookmarked = false,
    this.modelUsed = 'FLUX.1 Pro',
    this.toolApplied = 'Text to Image',
    this.aspectRatio = '16:9',
    this.dimensions = '1344x768',
    this.seed = 4291823,
    this.costCredits = 2.0,
    String? fullPrompt,
    this.negativePrompt = 'blurry, low quality, distorted, extra limbs, bad anatomy, text, watermark',
    this.createdAt = 'Oct 28, 2026',
  }) : fullPrompt = fullPrompt ?? maskedSummary;

  ExploreCardModel copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likeCount,
    String? modelUsed,
    String? toolApplied,
    String? aspectRatio,
    String? dimensions,
    int? seed,
    double? costCredits,
    String? fullPrompt,
    String? negativePrompt,
    String? createdAt,
  }) {
    return ExploreCardModel(
      id: id,
      authorName: authorName,
      authorHandle: authorHandle,
      authorAvatar: authorAvatar,
      title: title,
      previewUrl: previewUrl,
      category: category,
      maskedSummary: maskedSummary,
      remixFee: remixFee,
      creatorRoyaltyCut: creatorRoyaltyCut,
      remixCount: remixCount,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      modelUsed: modelUsed ?? this.modelUsed,
      toolApplied: toolApplied ?? this.toolApplied,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      dimensions: dimensions ?? this.dimensions,
      seed: seed ?? this.seed,
      costCredits: costCredits ?? this.costCredits,
      fullPrompt: fullPrompt ?? this.fullPrompt,
      negativePrompt: negativePrompt ?? this.negativePrompt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory ExploreCardModel.fromJson(Map<String, dynamic> json) {
    return ExploreCardModel(
      id: (json['id'] ?? '').toString(),
      authorName: json['author_name'] as String? ?? 'Creator',
      authorHandle: json['author_handle'] as String? ?? '@creator',
      authorAvatar: json['author_avatar'] as String? ??
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop',
      title: json['title'] as String? ?? 'Masterpiece',
      previewUrl: json['preview_image_url'] as String? ??
          json['preview_url'] as String? ??
          '',
      category: json['category'] as String? ?? 'General',
      maskedSummary: json['masked_summary'] as String? ??
          json['masked_prompt_summary'] as String? ??
          '',
      remixFee: (json['base_remix_fee'] as num?)?.toDouble() ??
          (json['remix_fee'] as num?)?.toDouble() ??
          4.0,
      creatorRoyaltyCut: (json['author_royalty_cut'] as num?)?.toDouble() ??
          (json['creator_royalty_cut'] as num?)?.toDouble() ??
          1.6,
      remixCount: (json['total_remixes'] as num?)?.toInt() ??
          (json['remix_count'] as num?)?.toInt() ??
          0,
      likeCount: (json['likes_count'] as num?)?.toInt() ??
          (json['like_count'] as num?)?.toInt() ??
          0,
      isLiked: json['is_liked'] as bool? ?? false,
      isBookmarked: json['is_bookmarked'] as bool? ?? false,
      modelUsed: json['model_used'] as String? ?? 'FLUX.1 Pro',
      toolApplied: json['tool_applied'] as String? ?? 'Text to Image',
      aspectRatio: json['aspect_ratio'] as String? ?? '16:9',
      dimensions: json['dimensions'] as String? ?? '1344x768',
      seed: (json['seed'] as num?)?.toInt() ?? 4291823,
      costCredits: (json['cost_credits'] as num?)?.toDouble() ?? 2.0,
      fullPrompt: json['full_prompt'] as String?,
      negativePrompt: json['negative_prompt'] as String? ??
          'blurry, low quality, distorted, extra limbs, bad anatomy, text, watermark',
      createdAt: json['created_at'] != null
          ? json['created_at'].toString()
          : 'Oct 28, 2026',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'author_name': authorName,
      'author_handle': authorHandle,
      'author_avatar': authorAvatar,
      'title': title,
      'preview_url': previewUrl,
      'preview_image_url': previewUrl,
      'category': category,
      'masked_summary': maskedSummary,
      'masked_prompt_summary': maskedSummary,
      'base_remix_fee': remixFee,
      'remix_fee': remixFee,
      'author_royalty_cut': creatorRoyaltyCut,
      'creator_royalty_cut': creatorRoyaltyCut,
      'total_remixes': remixCount,
      'remix_count': remixCount,
      'likes_count': likeCount,
      'like_count': likeCount,
      'is_liked': isLiked,
      'is_bookmarked': isBookmarked,
      'model_used': modelUsed,
      'tool_applied': toolApplied,
      'aspect_ratio': aspectRatio,
      'dimensions': dimensions,
      'seed': seed,
      'cost_credits': costCredits,
      'full_prompt': fullPrompt,
      'negative_prompt': negativePrompt,
      'created_at': createdAt,
    };
  }
}
