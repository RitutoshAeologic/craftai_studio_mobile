import 'package:flutter_test/flutter_test.dart';
import 'package:craftai_studio_mobile/data/models/collection_model.dart';
import 'package:craftai_studio_mobile/features/library/controllers/collection_controller.dart';
import 'package:get/get.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CollectionModel Cover Image & Zero Count Invariant Tests', () {
    test('fromJson sets coverImageUrl to null when itemCount is 0 even if raw cover_image_url exists', () {
      final json = {
        'id': 'test-col-1',
        'name': 'ss',
        'item_count': 0,
        'cover_image_url': 'https://example.com/stale_template.png',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final col = CollectionModel.fromJson(json);
      expect(col.itemCount, equals(0));
      expect(col.coverImageUrl, isNull);
    });

    test('fromJson sets coverImageUrl to null when joined collection_items count is 0', () {
      final json = {
        'id': 'test-col-2',
        'name': 'ss',
        'collection_items': [{'count': 0}],
        'cover_image_url': 'https://example.com/stale_template.png',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final col = CollectionModel.fromJson(json);
      expect(col.itemCount, equals(0));
      expect(col.coverImageUrl, isNull);
    });

    test('fromJson preserves coverImageUrl when itemCount > 0', () {
      final json = {
        'id': 'test-col-3',
        'name': 'ss',
        'item_count': 1,
        'cover_image_url': 'https://example.com/active.png',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final col = CollectionModel.fromJson(json);
      expect(col.itemCount, equals(1));
      expect(col.coverImageUrl, equals('https://example.com/active.png'));
    });

    test('copyWith automatically clears coverImageUrl when itemCount transitions to 0', () {
      final col = CollectionModel(
        id: 'test-col-4',
        name: 'ss',
        itemCount: 1,
        coverImageUrl: 'https://example.com/active.png',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = col.copyWith(itemCount: 0);
      expect(updated.itemCount, equals(0));
      expect(updated.coverImageUrl, isNull);
    });

    test('copyWith respects clearCoverImageUrl flag', () {
      final col = CollectionModel(
        id: 'test-col-5',
        name: 'ss',
        itemCount: 2,
        coverImageUrl: 'https://example.com/active.png',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updated = col.copyWith(clearCoverImageUrl: true);
      expect(updated.itemCount, equals(2));
      expect(updated.coverImageUrl, isNull);
    });
  });

  group('CollectionController Unsave Lifecycle Tests', () {
    late CollectionController controller;

    setUp(() {
      Get.reset();
      controller = Get.put(CollectionController());
    });

    tearDown(() {
      Get.reset();
    });

    test('Saving and then unsaving the last item clears collection cover and sets count to 0', () async {
      // Create a collection
      final col = await controller.createCollection(
        name: 'ss',
        coverImageUrl: 'https://example.com/img1.png',
      );

      // Save item
      await controller.toggleSaveItem(
        collectionId: col.id,
        itemId: 'item-1',
        imageUrl: 'https://example.com/img1.png',
      );

      expect(controller.isItemInCollection(col.id, 'item-1'), isTrue);
      expect(controller.getCollectionItems(col.id).length, equals(1));

      // Now unsave the item
      await controller.toggleSaveItem(
        collectionId: col.id,
        itemId: 'item-1',
        imageUrl: 'https://example.com/img1.png',
      );

      expect(controller.isItemInCollection(col.id, 'item-1'), isFalse);
      expect(controller.getCollectionItems(col.id), isEmpty);

      final updatedCol = controller.collections.firstWhere((c) => c.id == col.id);
      expect(updatedCol.itemCount, equals(0));
      expect(updatedCol.coverImageUrl, isNull);
    });
  });
}
