class CharacterModel {
  final String id;
  final String name;
  final List<String> referencePhotoUrls;
  final DateTime createdAt;

  CharacterModel({
    required this.id,
    required this.name,
    required this.referencePhotoUrls,
    required this.createdAt,
  });
}
