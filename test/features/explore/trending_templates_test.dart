import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import '../../mocks/fake_studio_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudioController studioController;
  late ShellController shellController;

  setUp(() {
    Get.reset();
    shellController = Get.put(ShellController());
    shellController.userCredits.value = 50.0;
    studioController = Get.put(StudioController(repository: FakeStudioRepository()));
  });

  tearDown(() {
    Get.reset();
  });

  group('Trending Templates Photo Remix Tests', () {
    test('startTemplateRemixGeneration correctly applies subject lock and attributes royalty', () async {
      final template = ExploreCardModel(
        id: '10000000-0000-4000-8000-000000000001',
        authorName: 'Kaito Vance',
        authorHandle: '@kaitovance',
        authorAvatar: 'https://images.unsplash.com/avatar.jpg',
        title: 'Cyberpunk Neo-Tokyo Rain',
        previewUrl: 'https://images.unsplash.com/cyberpunk.jpg',
        category: 'Cyberpunk',
        modelUsed: 'FLUX.1 Schnell',
        aspectRatio: '9:16',
        fullPrompt: 'Cinematic portrait of cyberpunk character in rain',
        maskedSummary: 'Cyber Ronin • Wet Neon Street',
        remixFee: 4.0,
        creatorRoyaltyCut: 1.6,
        remixCount: 485,
        likeCount: 1240,
        isTrending: true,
      );

      final tempPhoto = File('/tmp/test_user_photo.jpg');

      await studioController.startTemplateRemixGeneration(
        template: template,
        userPhoto: tempPhoto,
      );

      // 1. Check tab switch to Studio
      expect(shellController.currentIndex.value, 1);

      // 2. Check provenance attribution
      expect(studioController.remixedFromPromptId.value, template.id);

      // 3. Check reference image attachment
      expect(studioController.referenceImages.length, 1);
      expect(studioController.referenceImages.first, tempPhoto.path);

      // 4. Check subject-lock prompt constraint
      expect(
        studioController.promptController.text,
        startsWith('DO NOT CHANGE THE HUMAN SUBJECT. HUMAN SUBJECT — ABSOLUTE LOCK.'),
      );
      expect(
        studioController.promptController.text,
        contains(template.fullPrompt),
      );

      // 5. Check aspect ratio and model sync
      expect(studioController.selectedAspectRatio.value, '9:16');
      expect(studioController.selectedModel.value, 'flux');
    });

    test('startTemplateRemixGeneration handles encrypted recipe with maskedSummary fallback', () async {
      final template = ExploreCardModel(
        id: '10000000-0000-4000-8000-000000000002',
        authorName: 'Elena Rostova',
        authorHandle: '@elena_art',
        authorAvatar: 'https://images.unsplash.com/avatar.jpg',
        title: 'Golden Hour Portrait',
        previewUrl: 'https://images.unsplash.com/golden.jpg',
        category: 'Photorealism',
        modelUsed: 'FLUX.1 Schnell',
        aspectRatio: '1:1',
        fullPrompt: '', // Empty fullPrompt triggers fallback to maskedSummary
        maskedSummary: 'Natural Beauty • Golden Hour • [Secret Recipe Encrypted]',
        remixFee: 4.0,
        creatorRoyaltyCut: 1.6,
        remixCount: 100,
        likeCount: 500,
        isTrending: true,
      );

      final tempPhoto = File('/tmp/test_user_photo_2.jpg');

      await studioController.startTemplateRemixGeneration(
        template: template,
        userPhoto: tempPhoto,
      );

      expect(
        studioController.promptController.text,
        'DO NOT CHANGE THE HUMAN SUBJECT. HUMAN SUBJECT — ABSOLUTE LOCK. Natural Beauty • Golden Hour',
      );
      expect(studioController.selectedAspectRatio.value, '1:1');
    });
  });
}
