import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/explore/domain/models/category_model.dart';
import 'package:craftai_studio_mobile/features/explore/data/repositories/category_repository.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';

void main() {
  group('CategoryModel & Taxonomy Tests', () {
    test('CategoryModel correctly parses snake_case and camelCase json', () {
      final json1 = {
        'id': 'cat_1',
        'slug': 'photorealism',
        'name': 'Photorealism',
        'description': 'Real photography',
        'icon_name': 'camera',
        'sort_order': 1,
        'is_active': true,
      };

      final cat = CategoryModel.fromJson(json1);
      expect(cat.id, 'cat_1');
      expect(cat.slug, 'photorealism');
      expect(cat.name, 'Photorealism');
      expect(cat.iconName, 'camera');
      expect(cat.sortOrder, 1);
      expect(cat.isActive, true);

      final outJson = cat.toJson();
      expect(outJson['slug'], 'photorealism');
      expect(outJson['sort_order'], 1);
    });

    test('CategoryRepository maps raw styles to canonical taxonomy', () {
      final repo = CategoryRepository();

      expect(repo.getCanonicalCategory('photoreal'), 'Photorealism');
      expect(repo.getCanonicalCategory('Realistic Photo'), 'Photorealism');
      expect(repo.getCanonicalCategory('Anime / Manga'), 'Anime');
      expect(repo.getCanonicalCategory('anime cel'), 'Anime');
      expect(repo.getCanonicalCategory('Cyberpunk Neon'), 'Cyberpunk');
      expect(repo.getCanonicalCategory('Pixar 3D'), '3D Render');
      expect(repo.getCanonicalCategory('Renaissance'), 'Character');
      expect(repo.getCanonicalCategory(null), 'General');
      expect(repo.getCanonicalCategory(''), 'General');
      expect(repo.getCanonicalCategory('unknown_xyz'), 'General');
    });

    test('JobModel persists and deserializes category with safe fallback', () {
      final jobWithCategory = JobModel(
        jobId: 'job_123',
        type: 'IMAGE_GEN',
        status: 'completed',
        prompt: 'Futuristic city',
        previewUrl: 'https://example.com/city.jpg',
        creditsDeducted: 2.0,
        category: 'Cyberpunk',
        createdAt: DateTime.now(),
      );

      final json = jobWithCategory.toJson();
      expect(json['category'], 'Cyberpunk');

      final reconstructed = JobModel.fromJson(json);
      expect(reconstructed.category, 'Cyberpunk');

      final legacyJson = {
        'job_id': 'job_legacy',
        'type': 'IMAGE_GEN',
        'status': 'completed',
        'prompt': 'Legacy image',
        'preview_url': 'https://example.com/legacy.jpg',
      };
      final legacyJob = JobModel.fromJson(legacyJson);
      expect(legacyJob.category, 'General');
    });

    test('ExploreController filteredCards applies case-insensitive category matching', () {
      final controller = ExploreController();

      // Seed with cards of varying case
      controller.cards.assignAll([
        ExploreCardModel(
          id: 'card_1',
          authorName: 'A1',
          authorHandle: '@a1',
          authorAvatar: 'https://example.com/avatar1.jpg',
          title: 'Card 1',
          previewUrl: 'https://example.com/1.jpg',
          category: 'Anime',
          modelUsed: 'flux',
          aspectRatio: '1:1',
          maskedSummary: 'Prompt 1',
          remixFee: 1.0,
          creatorRoyaltyCut: 0.4,
          remixCount: 1,
          likeCount: 1,
        ),
        ExploreCardModel(
          id: 'card_2',
          authorName: 'A2',
          authorHandle: '@a2',
          authorAvatar: 'https://example.com/avatar2.jpg',
          title: 'Card 2',
          previewUrl: 'https://example.com/2.jpg',
          category: 'anime', // lowercase
          modelUsed: 'flux',
          aspectRatio: '1:1',
          maskedSummary: 'Prompt 2',
          remixFee: 1.0,
          creatorRoyaltyCut: 0.4,
          remixCount: 1,
          likeCount: 1,
        ),
        ExploreCardModel(
          id: 'card_3',
          authorName: 'A3',
          authorHandle: '@a3',
          authorAvatar: 'https://example.com/avatar3.jpg',
          title: 'Card 3',
          previewUrl: 'https://example.com/3.jpg',
          category: 'Photorealism',
          modelUsed: 'flux',
          aspectRatio: '1:1',
          maskedSummary: 'Prompt 3',
          remixFee: 1.0,
          creatorRoyaltyCut: 0.4,
          remixCount: 1,
          likeCount: 1,
        ),
      ]);

      // Category 'All' returns all 3
      controller.selectedCategory.value = 'All';
      expect(controller.filteredCards.length, 3);

      // Filtering with 'Anime' matches both 'Anime' and 'anime'
      controller.selectedCategory.value = 'Anime';
      expect(controller.filteredCards.length, 2);

      // Filtering with lowercase 'anime' also matches both
      controller.selectedCategory.value = 'anime';
      expect(controller.filteredCards.length, 2);

      // Filtering with 'Photorealism' matches only card_3
      controller.selectedCategory.value = 'Photorealism';
      expect(controller.filteredCards.length, 1);
      expect(controller.filteredCards.first.id, 'card_3');
    });
  });
}
