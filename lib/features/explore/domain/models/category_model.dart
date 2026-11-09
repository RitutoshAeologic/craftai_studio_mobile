class CategoryModel {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final String iconName;
  final int sortOrder;
  final bool isActive;

  const CategoryModel({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    this.iconName = 'sparkles',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: (json['id'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      description: json['description'] as String?,
      iconName: (json['icon_name'] ?? json['iconName'] ?? 'sparkles').toString(),
      sortOrder: (json['sort_order'] ?? json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: (json['is_active'] ?? json['isActive']) as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      if (description != null) 'description': description,
      'icon_name': iconName,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          slug.toLowerCase() == other.slug.toLowerCase();

  @override
  int get hashCode => slug.toLowerCase().hashCode;

  @override
  String toString() => 'CategoryModel(id: $id, slug: $slug, name: $name, sortOrder: $sortOrder)';
}
