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
  });

  ExploreCardModel copyWith({bool? isLiked, int? likeCount}) {
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
    );
  }
}
