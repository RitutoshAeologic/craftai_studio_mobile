class CollectionModel {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int itemCount;
  final bool isDefault;
  final bool isPrivate;
  final DateTime createdAt;
  final DateTime updatedAt;

  CollectionModel({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.itemCount = 0,
    this.isDefault = false,
    this.isPrivate = true,
    required this.createdAt,
    required this.updatedAt,
  });

  CollectionModel copyWith({
    String? name,
    String? description,
    String? coverImageUrl,
    bool clearCoverImageUrl = false,
    int? itemCount,
    bool? isDefault,
    bool? isPrivate,
    DateTime? updatedAt,
  }) {
    final updatedItemCount = itemCount ?? this.itemCount;
    return CollectionModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      coverImageUrl: (clearCoverImageUrl || updatedItemCount == 0)
          ? null
          : (coverImageUrl ?? this.coverImageUrl),
      itemCount: updatedItemCount,
      isDefault: isDefault ?? this.isDefault,
      isPrivate: isPrivate ?? this.isPrivate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    // Supports both direct counter-cache column (item_count) and joined collection_items(count)
    final countFromCol = json['item_count'] as num?;
    final countFromJoin = (json['collection_items'] as List?)?.firstOrNull?['count'] as num?;
    final resolvedCount = (countFromCol ?? countFromJoin ?? 0).toInt();

    final rawCover = json['cover_image_url'] as String?;
    final coverImageUrl = (resolvedCount > 0 && rawCover != null && rawCover.isNotEmpty)
        ? rawCover
        : null;

    return CollectionModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      coverImageUrl: coverImageUrl,
      itemCount: resolvedCount,
      isDefault: json['is_default'] as bool? ?? false,
      isPrivate: json['is_private'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cover_image_url': coverImageUrl,
      'item_count': itemCount,
      'is_default': isDefault,
      'is_private': isPrivate,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
