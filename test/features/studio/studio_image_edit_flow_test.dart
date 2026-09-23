import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_compile_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import '../../mocks/fake_studio_repository.dart';

class MockStudioRepository extends FakeStudioRepository {
  String lastExpandedRawPrompt = '';

  @override
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'groq',
  }) async {
    lastExpandedRawPrompt = rawPrompt;
    return (
      data: PromptExpandModel(
        masterPrompt: 'Enriched $rawPrompt, 85mm f/1.4 lens, Rembrandt lighting, 8k resolution',
        negativePrompt: 'blurry, distorted',
        modelUsed: 'google/gemini-2.5-flash (Live AI)',
      ),
      failure: null,
    );
  }

  @override
  Future<StudioResult<GenerationDispatchModel>> dispatchGeneration({
    required String prompt,
    String? characterId,
    List<String>? faceReferenceUrls,
    int width = 1024,
    int height = 1024,
    String? model,
    String? remixedFromPromptId,
  }) async {
    return (
      data: const GenerationDispatchModel(
        taskId: 'task_edit_123',
        tier: 'Tier 1 (InstantID Face-Lock)',
        status: 'ready',
        directImageUrl: 'https://example.com/edited.png',
      ),
      failure: null,
    );
  }

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) => null;

  @override
  Future<StudioResult<PromptCompileModel>> compileChatDelta({
    required String basePrompt,
    required String userInstruction,
    int turnCount = 1,
    String aiEngine = 'groq',
  }) async {
    return (
      data: const PromptCompileModel(
        compiledPrompt: 'Compiled',
        addedTags: [],
        removedTags: [],
        suggestedChips: [],
        modelUsed: 'groq',
      ),
      failure: null,
    );
  }

  @override
  Future<StudioResult<String>> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
  }) async => (data: 'task_123', failure: null);

  @override
  Future<StudioResult<String>> removeBackground({required String imageUrl}) async =>
      (data: 'https://example.com/cutout.png', failure: null);

  @override
  Future<StudioResult<RemixSessionModel>> createRemixSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
    double styleWeight = 0.60,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<RemixSessionModel>> getRemixSession({
    required String sessionId,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<RemixChatTurnResult>> sendRemixChatMessage({
    required String sessionId,
    required String userInstruction,
    String aiModel = 'groq',
    double? styleWeight,
  }) async => (data: null, failure: null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockStudioRepository mockRepo;
  late StudioController studioController;
  late ShellController shellController;

  setUp(() {
    Get.reset();
    mockRepo = MockStudioRepository();
    Get.put<IStudioRepository>(mockRepo);
    shellController = Get.put(ShellController());
    shellController.userCredits.value = 10.0;
    Get.put(LibraryController());
    studioController = Get.put(StudioController(repository: mockRepo));
  });

  tearDown(() {
    Get.reset();
  });

  group('MeiGen Image Edit & Prompt Refine Flow Tests', () {
    test('loadForImageEdit loads image1, pre-fills Edit image1 as follows:, and activates edit mode', () {
      const testImageUrl = 'https://example.com/retro_man.png';

      studioController.loadForImageEdit(imageUrl: testImageUrl);

      expect(studioController.isImageEditMode.value, isTrue);
      expect(studioController.referenceImages.length, 1);
      expect(studioController.referenceImages.first, testImageUrl);
      expect(studioController.promptController.text, 'Edit image1 as follows: ');
      expect(studioController.freeEditAttemptsRemaining.value, 5);
      // Pricing: Free edit attempt charges 0 Credits!
      expect(studioController.calculatedCreditCost, 0);
    });

    test('Option A prompt enhancement preserves Edit image1 as follows: prefix and enriches delta', () async {
      studioController.loadForImageEdit(imageUrl: 'https://example.com/photo.png');
      studioController.promptController.text = 'Edit image1 as follows: add a red leather jacket and sunglasses';

      await studioController.enhancePrompt();

      // What AI received to enhance was the user's delta edits:
      expect(mockRepo.lastExpandedRawPrompt, 'add a red leather jacket and sunglasses');

      // What was armed in geminiRefinedPrompt preserved the prefix:
      expect(
        studioController.geminiRefinedPrompt.value.startsWith('Edit image1 as follows:'),
        isTrue,
      );
      expect(
        studioController.geminiRefinedPrompt.value.contains('Enriched add a red leather jacket and sunglasses'),
        isTrue,
      );

      // What user sees in the input field remained clean:
      expect(
        studioController.promptController.text,
        'Edit image1 as follows: add a red leather jacket and sunglasses',
      );
    });

    test('Free edit attempt is consumed and decremented on successful generation', () async {
      studioController.loadForImageEdit(imageUrl: 'https://example.com/photo.png');
      studioController.promptController.text = 'Edit image1 as follows: make hair blonde';

      expect(studioController.freeEditAttemptsRemaining.value, 5);
      expect(studioController.calculatedCreditCost, 0);

      final initialCredits = shellController.userCredits.value;

      await studioController.generateVisual();

      // Zero credits deducted because free edit was active!
      expect(shellController.userCredits.value, initialCredits);
      // Free edit counter decremented from 5 to 4:
      expect(studioController.freeEditAttemptsRemaining.value, 4);
    });

    test('ExploreController publishCreation adds creation to Explore feed with 40% royalty', () {
      final exploreController = Get.put(ExploreController());
      final initialCount = exploreController.cards.length;

      exploreController.publishCreation(
        title: 'Retro 80s Vibe',
        prompt: 'Using my uploaded photo, 80s aesthetic',
        previewUrl: 'https://example.com/retro.png',
        category: 'Photorealism',
      );

      expect(exploreController.cards.length, initialCount + 1);
      final published = exploreController.cards.first;
      expect(published.title, 'Retro 80s Vibe');
      expect(published.category, 'Photorealism');
      expect(published.creatorRoyaltyCut, 1.6);
      expect(published.authorName, 'You');
    });
  });
}
