class CharacterModel {
  final String id;
  final String name;
  final String? gender;
  final List<String> referencePhotoUrls;
  final DateTime createdAt;

  CharacterModel({
    required this.id,
    required this.name,
    this.gender,
    required this.referencePhotoUrls,
    required this.createdAt,
  });

  factory CharacterModel.fromJson(Map<String, dynamic> json) {
    return CharacterModel(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      gender: json['gender'] as String?,
      referencePhotoUrls: (json['reference_photo_urls'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (gender != null) 'gender': gender,
      'reference_photo_urls': referencePhotoUrls,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
