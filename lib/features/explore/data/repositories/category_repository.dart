import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:craftai_studio_mobile/core/network/api_client.dart';
import 'package:craftai_studio_mobile/core/services/i_supabase_service.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import '../../domain/models/category_model.dart';

abstract class ICategoryRepository {
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false});
  List<CategoryModel> getCachedCategories();
  String getCanonicalCategory(String? rawCategory);
}

class CategoryRepository implements ICategoryRepository {
  static CategoryRepository? _instance;
  static CategoryRepository get instance => _instance ??= CategoryRepository();

  final ISupabaseService _supabase;
  final IApiClient _apiClient;
  final FlutterSecureStorage _storage;

  static const String _kCategoriesCacheKey = 'craftai_cached_categories_v1';

  static const List<CategoryModel> defaultCategories = [
    CategoryModel(id: 'cat_all', slug: 'all', name: 'All', iconName: 'sparkles', sortOrder: 0),
    CategoryModel(id: 'cat_photorealism', slug: 'photorealism', name: 'Photorealism', iconName: 'camera', sortOrder: 1),
    CategoryModel(id: 'cat_anime', slug: 'anime', name: 'Anime', iconName: 'palette', sortOrder: 2),
    CategoryModel(id: 'cat_cyberpunk', slug: 'cyberpunk', name: 'Cyberpunk', iconName: 'bolt', sortOrder: 3),
    CategoryModel(id: 'cat_3d_render', slug: '3d-render', name: '3D Render', iconName: 'cube', sortOrder: 4),
    CategoryModel(id: 'cat_character', slug: 'character', name: 'Character', iconName: 'person', sortOrder: 5),
    CategoryModel(id: 'cat_architecture', slug: 'architecture', name: 'Architecture', iconName: 'home', sortOrder: 6),
    CategoryModel(id: 'cat_product', slug: 'product', name: 'Product', iconName: 'shopping_bag', sortOrder: 7),
  ];

  List<CategoryModel> _memoryCache = List.of(defaultCategories);

  CategoryRepository({
    ISupabaseService? supabase,
    IApiClient? apiClient,
    FlutterSecureStorage? storage,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _apiClient = apiClient ?? ApiClient.instance,
        _storage = storage ?? const FlutterSecureStorage();

  @override
  List<CategoryModel> getCachedCategories() => List.unmodifiable(_memoryCache);

  @override
  Future<List<CategoryModel>> getCategories({bool forceRefresh = false}) async {
    if (!forceRefresh && _memoryCache.length > defaultCategories.length) {
      return List.unmodifiable(_memoryCache);
    }

    // Try reading from local secure storage if memory cache is bare default
    if (!forceRefresh) {
      try {
        final cachedJson = await _storage.read(key: _kCategoriesCacheKey);
        if (cachedJson != null && cachedJson.isNotEmpty) {
          final List decoded = jsonDecode(cachedJson);
          _memoryCache = decoded.map((e) => CategoryModel.fromJson(Map<String, dynamic>.from(e))).toList();
          return List.unmodifiable(_memoryCache);
        }
      } catch (e) {
        AppLogger.d('Category storage cache read skipped: $e', tag: 'CATEGORY_REPO');
      }
    }

    // 1. Try Supabase public.categories
    try {
      final res = await _supabase
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      if (res.isNotEmpty) {
        final List<CategoryModel> fetched = [];
        // Ensure "All" is always first
        if (!res.any((r) => (r['slug']?.toString().toLowerCase() == 'all'))) {
          fetched.add(defaultCategories.first);
        }
        for (final item in res) {
          fetched.add(CategoryModel.fromJson(Map<String, dynamic>.from(item)));
        }
        _memoryCache = fetched;
        _saveToCache(fetched);
        AppLogger.s('Loaded ${fetched.length} categories from Supabase', tag: 'CATEGORY_REPO');
        return List.unmodifiable(_memoryCache);
      }
    } catch (e) {
      AppLogger.d('Supabase categories fetch notice: $e. Trying Backend API.', tag: 'CATEGORY_REPO');
    }

    // 2. Fallback to Backend FastAPI Endpoint
    try {
      final response = await _apiClient.get('/api/v1/categories');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final rawList = data is Map ? (data['categories'] as List?) : (data as List?);
        if (rawList != null && rawList.isNotEmpty) {
          final List<CategoryModel> fetched = [];
          if (!rawList.any((r) => (r['slug']?.toString().toLowerCase() == 'all'))) {
            fetched.add(defaultCategories.first);
          }
          for (final item in rawList) {
            fetched.add(CategoryModel.fromJson(Map<String, dynamic>.from(item)));
          }
          _memoryCache = fetched;
          _saveToCache(fetched);
          AppLogger.s('Loaded ${fetched.length} categories from Backend API', tag: 'CATEGORY_REPO');
          return List.unmodifiable(_memoryCache);
        }
      }
    } catch (e) {
      AppLogger.d('Backend categories API notice: $e. Using canonical fallbacks.', tag: 'CATEGORY_REPO');
    }

    return List.unmodifiable(_memoryCache);
  }

  void _saveToCache(List<CategoryModel> items) {
    try {
      final jsonStr = jsonEncode(items.map((c) => c.toJson()).toList());
      _storage.write(key: _kCategoriesCacheKey, value: jsonStr);
    } catch (e) {
      AppLogger.w('Failed to persist categories to storage: $e', tag: 'CATEGORY_REPO');
    }
  }

  @override
  String getCanonicalCategory(String? rawCategory) {
    if (rawCategory == null || rawCategory.trim().isEmpty) return 'General';
    final clean = rawCategory.trim().toLowerCase();

    for (final c in _memoryCache) {
      if (c.slug.toLowerCase() == clean || c.name.toLowerCase() == clean) {
        return c.name;
      }
    }

    // Common synonym heuristics
    if (clean.contains('photo') || clean.contains('real') || clean.contains('cinematic') || clean.contains('hollywood') || clean.contains('film')) return 'Photorealism';
    if (clean.contains('anime') || clean.contains('manga')) return 'Anime';
    if (clean.contains('cyber') || clean.contains('neon')) return 'Cyberpunk';
    if (clean.contains('3d') || clean.contains('pixar') || clean.contains('render') || clean.contains('clay')) return '3D Render';
    if (clean.contains('character') || clean.contains('portrait') || clean.contains('renaissance') || clean.contains('oil') || clean.contains('paint')) return 'Character';
    if (clean.contains('arch') || clean.contains('building') || clean.contains('interior')) return 'Architecture';
    if (clean.contains('product') || clean.contains('commercial') || clean.contains('pack')) return 'Product';

    return 'General';
  }
}
