import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudioController controller;
  late ShellController shellController;

  setUp(() {
    Get.reset();
    shellController = Get.put(ShellController());
    shellController.userCredits.value = 100.0;
    controller = Get.put(StudioController());
  });

  tearDown(() {
    Get.reset();
  });

  group('Studio Simplified User-Friendly Flow Tests', () {
    test('1-tap visual style selection updates preset and matching aspect ratio', () {
      expect(controller.selectedStylePreset.value, 'Realistic Photo');

      // Select Anime / Manga (which defaults to 9:16 vertical for stories/wallpapers)
      final animeStyle = controller.visualStyles.firstWhere((s) => s['name'] == 'Anime / Manga');
      controller.selectVisualStyle(animeStyle);
      expect(controller.selectedStylePreset.value, 'Anime / Manga');
      expect(controller.selectedAspectRatio.value, '9:16');

      // Select 3D Cartoon (which defaults to 1:1 post)
      final cartoonStyle = controller.visualStyles.firstWhere((s) => s['name'] == '3D Cartoon');
      controller.selectVisualStyle(cartoonStyle);
      expect(controller.selectedStylePreset.value, '3D Cartoon');
      expect(controller.selectedAspectRatio.value, '1:1');
    });

    test('Surprise Me 🎲 populates prompt and style when text box is empty', () {
      controller.promptController.text = '';
      expect(controller.promptLength.value, 0);

      // Trigger surprise me
      controller.triggerSurpriseMe();

      // Prompt should now be populated with a curated creative idea
      expect(controller.promptController.text.isNotEmpty, isTrue);
      expect(controller.selectedStylePreset.value.isNotEmpty, isTrue);
    });

    test('Consecutive Surprise Me taps cycle through creative ideas', () {
      controller.triggerSurpriseMe();
      final firstPrompt = controller.promptController.text;

      controller.triggerSurpriseMe();
      final secondPrompt = controller.promptController.text;

      expect(firstPrompt, isNot(equals(secondPrompt)));
    });

    test('In-Studio Result Hero Card state transitions correctly', () {
      expect(controller.showResultHero.value, isFalse);
      expect(controller.lastGeneratedImageUrl.value, isNull);

      // Simulate completed generation reveal
      controller.lastGeneratedImageUrl.value = 'https://craftai.cdn/images/test_hero.png';
      controller.showResultHero.value = true;

      expect(controller.showResultHero.value, isTrue);
      expect(controller.lastGeneratedImageUrl.value, 'https://craftai.cdn/images/test_hero.png');

      // Dismiss hero card
      controller.closeResultHero();
      expect(controller.showResultHero.value, isFalse);
    });

    test('Visual styles list contains expected presets with icons and aspect ratios', () {
      expect(controller.visualStyles.length, 6);
      final names = controller.visualStyles.map((s) => s['name']).toList();
      expect(names, contains('Realistic Photo'));
      expect(names, contains('3D Cartoon'));
      expect(names, contains('Anime / Manga'));
      expect(names, contains('Cyberpunk Neon'));
      expect(names, contains('Cinematic Art'));
      expect(names, contains('Oil Painting'));
    });

    test('enhancePrompt on EMPTY prompt rejects immediately without setting isEnhancing', () async {
      controller.promptController.text = '';
      expect(controller.isEnhancing.value, isFalse);

      await controller.enhancePrompt();

      // Critical validation: isEnhancing must remain FALSE!
      expect(controller.isEnhancing.value, isFalse);
      expect(controller.isPromptEnhanced, isFalse);
      expect(controller.promptController.text, isEmpty);
    });

    test('generateVisual on EMPTY prompt rejects immediately without setting isGenerating', () async {
      controller.promptController.text = '';
      final initialCredits = shellController.userCredits.value;

      await controller.generateVisual();

      // Critical validation: must NOT start generating or deduct credits
      expect(controller.isGenerating.value, isFalse);
      expect(shellController.userCredits.value, initialCredits);
    });

    test('aiEditSubjectLock on EMPTY prompt rejects without modifying prompt', () {
      controller.promptController.text = '';

      controller.aiEditSubjectLock();

      expect(controller.promptController.text, isEmpty);
    });

    test('Enhance loading state is completely independent from generation state', () {
      controller.isEnhancing.value = true;

      // isGenerating must remain false when isEnhancing is active
      expect(controller.isGenerating.value, isFalse);
      expect(controller.isBusy, isTrue);

      controller.isEnhancing.value = false;
      expect(controller.isBusy, isFalse);
    });
  });
}
