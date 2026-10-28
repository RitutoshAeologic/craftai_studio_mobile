import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/collection_model.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';

/// [CollectionController] manages user-created bookmark collections (folders),
/// item bookmarking, and Supabase synchronization.
class CollectionController extends GetxController {
  final RxList<CollectionModel> collections = <CollectionModel>[
    CollectionModel(
      id: 'col_favorites',
      name: 'Favorites',
      description: 'Quick bookmarks of inspiring community artwork',
      coverImageUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop',
      itemCount: 4,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
    ),
    CollectionModel(
      id: 'col_cyberpunk',
      name: 'Cyberpunk & Sci-Fi',
      description: 'Futuristic neon aesthetics and androids',
      coverImageUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop',
      itemCount: 6,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now(),
    ),
    CollectionModel(
      id: 'col_portraits',
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

  @override
  void onInit() {
    super.onInit();
    fetchCollections();
  }

  /// Fetches collections from Supabase if connected
  Future<void> fetchCollections() async {
    try {
      final client = SupabaseService.client;
      if (client.auth.currentUser == null) return;

      final res = await client
          .from('collections')
          .select('*, collection_items(count)')
          .order('updated_at', ascending: false);

      final loaded = (res as List)
          .map((row) => CollectionModel.fromJson(row as Map<String, dynamic>))
          .toList();

      if (loaded.isNotEmpty) {
        collections.assignAll(loaded);
      }
    } catch (_) {
      // Graceful fallback to local mock collections
    }
  }

  /// Creates a new named collection folder with immediate optimistic UI update
  Future<CollectionModel> createCollection({
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    HapticFeedback.lightImpact();
    final newCol = CollectionModel(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      description: description?.trim(),
      coverImageUrl: coverImageUrl,
      itemCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    collections.insert(0, newCol);

    // Sync to Supabase in background
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('collections').insert({
          'name': newCol.name,
          'description': newCol.description,
          'user_id': userId,
          'is_private': true,
        });
      }
    } catch (_) {
      // Offline support: local item remains
    }

    return newCol;
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

    if (isAlreadySaved) {
      currentSet.remove(collectionId);
      // Decrement count
      final idx = collections.indexWhere((c) => c.id == collectionId);
      if (idx != -1) {
        final col = collections[idx];
        collections[idx] = col.copyWith(
          itemCount: col.itemCount > 0 ? col.itemCount - 1 : 0,
        );
      }
    } else {
      currentSet.add(collectionId);
      // Increment count
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

    // Supabase sync
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        if (isAlreadySaved) {
          await client
              .from('collection_items')
              .delete()
              .eq('collection_id', collectionId)
              .or('job_id.eq.$itemId,explore_prompt_id.eq.$itemId');
        } else {
          await client.from('collection_items').insert({
            'collection_id': collectionId,
            'user_id': userId,
            'image_url': imageUrl,
            'explore_prompt_id': itemId,
          });
        }
      }
    } catch (_) {
      // Handled gracefully in offline mode
    }
  }
}
