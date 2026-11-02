import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';

/// Abstract domain repository contract for the Explore community feed.
///
/// Follows Clean Architecture: Presentation layer interacts only with this
/// interface, decoupling UI controllers from Supabase and REST API details.
abstract class IExploreRepository {
  /// Fetches a paginated slice of community creations matching active filters.
  Future<List<ExploreCardModel>> getExploreCards({
    required int page,
    required int pageSize,
    String? category,
    String? model,
    Set<String>? aspectRatios,
    String? searchQuery,
  });

  /// Fetches creations similar to [cardId] from the backend pgvector engine.
  Future<List<ExploreCardModel>> getSimilarCreations(String cardId);

  /// Toggles like status on a card in the remote datastore.
  Future<bool> toggleLike(String cardId, bool isLiked);
}

