import 'package:dio/dio.dart';
import 'package:craftai_studio_mobile/core/network/api_client.dart';
import 'package:craftai_studio_mobile/core/services/i_supabase_service.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/core/utils/async_worker.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';

/// Remote data source responsible for all network and database operations
/// related to the Explore Discovery feed.
class ExploreRemoteDataSource {
  final ISupabaseService _supabase;
  final IApiClient _apiClient;

  ExploreRemoteDataSource({
    ISupabaseService? supabase,
    IApiClient? apiClient,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _apiClient = apiClient ?? ApiClient.instance;

  /// Fetches a paginated slice of community creations from Supabase `explore_prompts`
  /// with server-side filtering and background isolate deserialization.
  Future<List<ExploreCardModel>> fetchExploreCards({
    required int page,
    required int pageSize,
    String? category,
    String? model,
    Set<String>? aspectRatios,
    String? searchQuery,
  }) async {
    final from = page * pageSize;
    final to = from + pageSize - 1;

    var query = _supabase.from('explore_prompts').select('*');

    // Server-side filter matching
    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }
    if (model != null && model.isNotEmpty && model != 'All Models') {
      query = query.eq('model_used', model);
    }

    final res = await query
        .order('created_at', ascending: false)
        .range(from, to);

    return await AsyncWorker.parseList(
      res as List,
      (json) => ExploreCardModel.fromJson(json),
    );
  }

  /// Fetches vector-similar community creations via backend pgvector endpoint
  Future<List<ExploreCardModel>> fetchSimilarCreations(String cardId) async {
    try {
      final res = await _apiClient.get(
        '/explore/similar/$cardId',
        options: Options(
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

      if (res.statusCode == 200 && res.data is List) {
        return await AsyncWorker.parseList(
          res.data as List,
          (item) => ExploreCardModel.fromJson(item),
        );
      }
    } catch (e) {
      AppLogger.d('Backend similar creations API skipped or offline: $e', tag: 'EXPLORE_DS');
    }
    return <ExploreCardModel>[];
  }

  /// Toggles like counter in Supabase
  Future<bool> toggleLike(String cardId, bool isLiked) async {
    try {
      await _supabase.from('explore_prompts').update({
        'likes_count': isLiked ? 1 : 0,
      }).eq('id', cardId);
      return true;
    } catch (e) {
      AppLogger.d('Cloud like sync skipped: $e', tag: 'EXPLORE_DS');
      return false;
    }
  }
}
