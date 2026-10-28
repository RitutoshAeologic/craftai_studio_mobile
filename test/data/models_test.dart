import 'package:flutter_test/flutter_test.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/data/models/collection_model.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/data/models/wallet_model.dart';
import 'package:craftai_studio_mobile/data/models/character_model.dart';
import 'package:craftai_studio_mobile/data/models/collection_item_model.dart';

void main() {
  group('JobModel JSON serialization & schema adaptability', () {
    test('JobModel parses Supabase response with legacy column names', () {
      final json = {
        'id': 'job_123',
        'job_id': 'job_uuid_456',
        'type': 'IMAGE_GEN',
        'status': 'completed',
        'prompt': 'A cyberpunk cat on a neon rooftop',
        'preview_url': 'https://example.com/cat.png',
        'master_url': 'https://example.com/cat_master.png',
        'credits_deducted': 2.5,
        'is_download_unlocked': true,
        'download_cost': 2.0,
        'created_at': '2026-10-28T10:00:00Z',
      };

      final job = JobModel.fromJson(json);
      expect(job.jobId, equals('job_uuid_456'));
      expect(job.prompt, equals('A cyberpunk cat on a neon rooftop'));
      expect(job.previewUrl, equals('https://example.com/cat.png'));
      expect(job.masterUrl, equals('https://example.com/cat_master.png'));
      expect(job.creditsDeducted, equals(2.5));
      expect(job.isDownloadUnlocked, isTrue);

      final out = job.toJson();
      expect(out['job_id'], equals('job_uuid_456'));
      expect(out['prompt'], equals('A cyberpunk cat on a neon rooftop'));
      expect(out['prompt_text'], equals('A cyberpunk cat on a neon rooftop'));
      expect(out['preview_url'], equals('https://example.com/cat.png'));
      expect(out['preview_image_url'], equals('https://example.com/cat.png'));
    });

    test('JobModel parses Supabase response with new column names', () {
      final json = {
        'id': 'job_789',
        'prompt_text': 'Cyber samurai in rain',
        'preview_image_url': 'https://example.com/samurai.png',
        'tool_applied': 'upscale',
        'aspect_ratio': '16:9',
        'dimensions': '1920x1080',
        'seed': 9999,
      };

      final job = JobModel.fromJson(json);
      expect(job.jobId, equals('job_789'));
      expect(job.prompt, equals('Cyber samurai in rain'));
      expect(job.previewUrl, equals('https://example.com/samurai.png'));
      expect(job.toolApplied, equals('upscale'));
      expect(job.aspectRatio, equals('16:9'));
      expect(job.seed, equals(9999));
    });
  });

  group('CollectionModel JSON serialization & counter cache', () {
    test('CollectionModel parses direct item_count column', () {
      final json = {
        'id': 'col_01',
        'name': 'Sci-Fi Collection',
        'description': 'Neon cities',
        'cover_image_url': 'https://example.com/cover.jpg',
        'item_count': 12,
        'is_default': false,
        'is_private': true,
        'created_at': '2026-10-28T12:00:00Z',
        'updated_at': '2026-10-28T12:30:00Z',
      };

      final col = CollectionModel.fromJson(json);
      expect(col.id, equals('col_01'));
      expect(col.itemCount, equals(12));
      expect(col.isDefault, isFalse);

      final out = col.toJson();
      expect(out['id'], equals('col_01'));
      expect(out['item_count'], equals(12));
    });

    test('CollectionModel falls back to joined collection_items count', () {
      final json = {
        'id': 'col_02',
        'name': 'All Saved',
        'is_default': true,
        'collection_items': [
          {'count': 7}
        ],
      };

      final col = CollectionModel.fromJson(json);
      expect(col.id, equals('col_02'));
      expect(col.itemCount, equals(7));
      expect(col.isDefault, isTrue);
    });
  });

  group('ExploreCardModel JSON serialization & multi-alias compatibility', () {
    test('ExploreCardModel resolves masked_prompt_summary and base_remix_fee', () {
      final json = {
        'id': 'exp_99',
        'title': 'Neon Dragon',
        'preview_url': 'https://example.com/dragon.jpg',
        'category': 'Fantasy',
        'masked_prompt_summary': 'Glowing emerald dragon over Tokyo',
        'base_remix_fee': 4.0,
        'author_royalty_cut': 1.6,
        'total_remixes': 25,
        'likes_count': 150,
      };

      final card = ExploreCardModel.fromJson(json);
      expect(card.id, equals('exp_99'));
      expect(card.title, equals('Neon Dragon'));
      expect(card.maskedSummary, equals('Glowing emerald dragon over Tokyo'));
      expect(card.previewUrl, equals('https://example.com/dragon.jpg'));
      expect(card.remixFee, equals(4.0));
      expect(card.creatorRoyaltyCut, equals(1.6));
      expect(card.remixCount, equals(25));
      expect(card.likeCount, equals(150));

      final out = card.toJson();
      expect(out['masked_summary'], equals('Glowing emerald dragon over Tokyo'));
      expect(out['masked_prompt_summary'], equals('Glowing emerald dragon over Tokyo'));
      expect(out['preview_url'], equals('https://example.com/dragon.jpg'));
      expect(out['preview_image_url'], equals('https://example.com/dragon.jpg'));
      expect(out['base_remix_fee'], equals(4.0));
      expect(out['remix_fee'], equals(4.0));
    });
  });

  group('WalletModel & CharacterModel & CollectionItemModel', () {
    test('WalletModel parses and serializes correctly', () {
      final json = {
        'purchased_balance': 20.0,
        'earned_royalty_balance': 30.5,
        'free_daily_balance': 500.0,
        'total_generations': 14,
        'total_royalties_earned': 30.5,
      };

      final wallet = WalletModel.fromJson(json);
      expect(wallet.purchasedBalance, equals(20.0));
      expect(wallet.earnedRoyaltyBalance, equals(30.5));
      expect(wallet.totalSpendable, equals(550.5));
      expect(wallet.isEligibleForPayout, isTrue);

      final out = wallet.toJson();
      expect(out['purchased_balance'], equals(20.0));
      expect(out['earned_royalty_balance'], equals(30.5));
    });

    test('CharacterModel parses and serializes correctly', () {
      final json = {
        'id': 'char_1',
        'name': 'Elena',
        'gender': 'female',
        'reference_photo_urls': ['https://example.com/p1.jpg', 'https://example.com/p2.jpg'],
        'created_at': '2026-10-28T12:00:00Z',
      };

      final character = CharacterModel.fromJson(json);
      expect(character.id, equals('char_1'));
      expect(character.name, equals('Elena'));
      expect(character.referencePhotoUrls.length, equals(2));

      final out = character.toJson();
      expect(out['name'], equals('Elena'));
      expect(out['gender'], equals('female'));
    });

    test('CollectionItemModel parses and serializes correctly', () {
      final json = {
        'id': 'item_1',
        'collection_id': 'col_1',
        'explore_prompt_id': 'exp_1',
        'image_url': 'https://example.com/pic.jpg',
        'user_id': 'usr_1',
        'created_at': '2026-10-28T12:00:00Z',
      };

      final item = CollectionItemModel.fromJson(json);
      expect(item.id, equals('item_1'));
      expect(item.explorePromptId, equals('exp_1'));
      expect(item.imageUrl, equals('https://example.com/pic.jpg'));

      final out = item.toJson();
      expect(out['collection_id'], equals('col_1'));
      expect(out['explore_prompt_id'], equals('exp_1'));
    });
  });
}
