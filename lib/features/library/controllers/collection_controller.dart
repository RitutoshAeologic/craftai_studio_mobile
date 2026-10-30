import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/data/models/collection_model.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';

/// [CollectionController] manages user-created bookmark collections (folders),
/// item bookmarking, and Supabase synchronization.
class CollectionController extends GetxController {
  final RxList<CollectionModel> collections = <CollectionModel>[
    CollectionModel(
      id: '00000000-0000-4000-8000-000000000101',
      name: 'Favorites',
      description: 'Quick bookmarks of inspiring community artwork',
      coverImageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop',
      itemCount: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
    ),
    CollectionModel(
      id: '00000000-0000-4000-8000-000000000102',
      name: 'Cyberpunk & Sci-Fi',
      description: 'Futuristic neon aesthetics and androids',
      coverImageUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop',
      itemCount: 6,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    CollectionModel(
      id: '00000000-0000-4000-8000-000000000103',
      name: 'Character References',
      description: 'Faces, poses, and lighting inspiration',
      coverImageUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop',
      itemCount: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now(),
    ),
  ].obs;

  /// Map of `itemId` -> Set of `collectionId`s for O(1) bookmark status lookups
  final RxMap<String, Set<String>> itemCollectionMap = <String, Set<String>>{}.obs;

  final RxBool isLoading = false.obs;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void onInit() {
    super.onInit();
    fetchCollections();
  }

  /// Fetches collections and saved items from Supabase if connected
  Future<void> fetchCollections() async {
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      isLoading.value = true;

      // 1. Fetch user's collections
      final res = await client
          .from('collections')
          .select('*, collection_items(count)')
          .order('updated_at', ascending: false);

      final loaded = (res as List)
          .map((row) => CollectionModel.fromJson(row as Map<String, dynamic>))
          .toList();

      if (loaded.isNotEmpty) {
        collections.assignAll(loaded);
        AppLogger.s('Loaded ${loaded.length} collections from Supabase', tag: 'COLLECTIONS');
      }

      // 2. Fetch all saved bookmark mappings for O(1) state lookup
      final itemsRes = await client
          .from('collection_items')
          .select('collection_id, job_id, explore_prompt_id, item_id')
          .eq('user_id', userId);

      final map = <String, Set<String>>{};
      for (final row in itemsRes as List) {
        final cId = row['collection_id']?.toString();
        final rawTargets = [row['job_id'], row['explore_prompt_id'], row['item_id']];
        for (final target in rawTargets) {
          if (cId != null && target != null) {
            final tId = target.toString();
            map.putIfAbsent(tId, () => <String>{}).add(cId);
          }
        }
      }
      itemCollectionMap.assignAll(map);
      AppLogger.s('Synchronized ${map.length} saved bookmarks from Supabase', tag: 'COLLECTIONS');
    } catch (e) {
      AppLogger.d('Cloud collection sync skipped: $e', tag: 'COLLECTIONS');
    } finally {
      isLoading.value = false;
    }
  }

  /// Creates a new named collection folder with optimistic UI and Supabase persistence
  Future<CollectionModel> createCollection({
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    HapticFeedback.lightImpact();
    CollectionModel createdCol;

    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        final res = await client.from('collections').insert({
          'name': name.trim(),
          'description': description?.trim(),
          'cover_image_url': coverImageUrl,
          'user_id': userId,
          'is_private': true,
        }).select('*, collection_items(count)').single();

        createdCol = CollectionModel.fromJson(res);
        collections.insert(0, createdCol);
        AppLogger.s('Created collection "${createdCol.name}" with ID: ${createdCol.id} in Supabase', tag: 'COLLECTIONS');
        return createdCol;
      }
    } catch (e) {
      AppLogger.e('Failed to sync collection to Supabase: $e', tag: 'COLLECTIONS');
    }

    // Offline / fallback collection
    createdCol = CollectionModel(
      id: '00000000-0000-4000-8000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0')}',
      name: name.trim(),
      description: description?.trim(),
      coverImageUrl: coverImageUrl,
      itemCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    collections.insert(0, createdCol);
    return createdCol;
  }

  /// Checks if an item is bookmarked in a specific collection
  bool isItemInCollection(String collectionId, String itemId) {
    return itemCollectionMap[itemId]?.contains(collectionId) ?? false;
  }

  /// Toggles saving an item into a collection
  Future<void> toggleSaveItem({
    required String collectionId,
    required String itemId,
    required String imageUrl,
  }) async {
    HapticFeedback.lightImpact();
    final currentSet = itemCollectionMap[itemId] ?? <String>{};
    final isAlreadySaved = currentSet.contains(collectionId);

    // Optimistic UI state update
    if (isAlreadySaved) {
      currentSet.remove(collectionId);
      final idx = collections.indexWhere((c) => c.id == collectionId);
      if (idx != -1) {
        final col = collections[idx];
        collections[idx] = col.copyWith(
          itemCount: col.itemCount > 0 ? col.itemCount - 1 : 0,
        );
      }
    } else {
      currentSet.add(collectionId);
      final idx = collections.indexWhere((c) => c.id == collectionId);
      if (idx != -1) {
        final col = collections[idx];
        collections[idx] = col.copyWith(
          itemCount: col.itemCount + 1,
          coverImageUrl: col.coverImageUrl ?? imageUrl,
        );
      }
    }

    itemCollectionMap[itemId] = Set<String>.from(currentSet);

    // Supabase synchronization
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        String targetCollectionId = collectionId;

        // If collectionId is not a valid UUID (e.g. legacy local id), find or create real UUID in Supabase
        if (!_uuidRegex.hasMatch(collectionId)) {
          final colName = collections.firstWhereOrNull((c) => c.id == collectionId)?.name ?? 'Favorites';
          final existing = await client
              .from('collections')
              .select('id')
              .eq('user_id', userId)
              .eq('name', colName)
              .maybeSingle();

          if (existing != null && existing['id'] != null) {
            targetCollectionId = existing['id'].toString();
          } else {
            final created = await client.from('collections').insert({
              'user_id': userId,
              'name': colName,
              'is_private': true,
              'cover_image_url': imageUrl,
            }).select('id').single();
            targetCollectionId = created['id'].toString();
          }
        }

        final isItemUuid = _uuidRegex.hasMatch(itemId);

        if (isAlreadySaved) {
          var query = client.from('collection_items').delete().eq('collection_id', targetCollectionId);
          if (isItemUuid) {
            query = query.or('job_id.eq.$itemId,explore_prompt_id.eq.$itemId,item_id.eq.$itemId');
          } else {
            query = query.eq('item_id', itemId);
          }
          await query;
          AppLogger.s('Removed item $itemId from collection $targetCollectionId in Supabase', tag: 'COLLECTIONS');
        } else {
          final payload = <String, dynamic>{
            'collection_id': targetCollectionId,
            'user_id': userId,
            'image_url': imageUrl,
            'item_id': itemId,
          };
          if (isItemUuid) {
            try {
              final isExplore = await client
                  .from('explore_prompts')
                  .select('id')
                  .eq('id', itemId)
                  .maybeSingle();
              if (isExplore != null) {
                payload['explore_prompt_id'] = itemId;
              } else {
                final isJob = await client
                    .from('jobs')
                    .select('id')
                    .eq('id', itemId)
                    .maybeSingle();
                if (isJob != null) {
                  payload['job_id'] = itemId;
                }
              }
            } catch (_) {}
          }
          try {
            await client.from('collection_items').insert(payload);
          } catch (insertErr) {
            // Resilient fallback: insert with item_id only so save NEVER fails
            await client.from('collection_items').insert({
              'collection_id': targetCollectionId,
              'user_id': userId,
              'image_url': imageUrl,
              'item_id': itemId,
            });
          }
          AppLogger.s('Persisted item $itemId to Supabase collection $targetCollectionId', tag: 'COLLECTIONS');
        }
      }
    } catch (e) {
      AppLogger.e('Supabase collection sync error: $e', tag: 'COLLECTIONS');
    }
  }
}
