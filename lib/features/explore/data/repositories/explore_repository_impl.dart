import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import '../../domain/repositories/i_explore_repository.dart';
import '../datasources/explore_remote_datasource.dart';

/// Implementation of [IExploreRepository] that orchestrates data access
/// through [ExploreRemoteDataSource].
class ExploreRepositoryImpl implements IExploreRepository {
  final ExploreRemoteDataSource _remoteDataSource;

  ExploreRepositoryImpl({
    ExploreRemoteDataSource? remoteDataSource,
  }) : _remoteDataSource = remoteDataSource ?? ExploreRemoteDataSource();

  @override
  Future<List<ExploreCardModel>> getExploreCards({
    required int page,
    required int pageSize,
    String? category,
    String? model,
    Set<String>? aspectRatios,
    String? searchQuery,
  }) async {
    try {
      return await _remoteDataSource.fetchExploreCards(
        page: page,
        pageSize: pageSize,
        category: category,
        model: model,
        aspectRatios: aspectRatios,
        searchQuery: searchQuery,
      );
    } catch (e) {
      AppLogger.w('ExploreRepositoryImpl getExploreCards error: $e', tag: 'EXPLORE_REPO');
      rethrow;
    }
  }

  @override
  Future<List<ExploreCardModel>> getSimilarCreations(String cardId) async {
    try {
      return await _remoteDataSource.fetchSimilarCreations(cardId);
    } catch (e) {
      AppLogger.w('ExploreRepositoryImpl getSimilarCreations error: $e', tag: 'EXPLORE_REPO');
      return <ExploreCardModel>[];
    }
  }

  @override
  Future<bool> toggleLike(String cardId, bool isLiked) async {
    try {
      return await _remoteDataSource.toggleLike(cardId, isLiked);
    } catch (e) {
      AppLogger.w('ExploreRepositoryImpl toggleLike error: $e', tag: 'EXPLORE_REPO');
      return false;
    }
  }
}

