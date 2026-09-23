import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/creation_studio_view.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/domain/failures/studio_failure.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_compile_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import '../../mocks/fake_studio_repository.dart';

class MockControlledStudioRepository extends FakeStudioRepository {
  Completer<GenerationDispatchModel>? completer;
  bool shouldFail = false;

  @override
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'gemini',
  }) async {
    return (
      data: const PromptExpandModel(
        masterPrompt: 'Controlled refined prompt',
        negativePrompt: 'blurry',
        modelUsed: 'gemini',
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
    if (shouldFail) {
      return (
        data: null,
        failure: const StudioValidationFailure('Your prompt exceeds the maximum length limit. Please shorten it slightly and try again.'),
      );
    }
    if (completer != null) {
      final data = await completer!.future;
      return (data: data, failure: null);
    }
    return (
      data: const GenerationDispatchModel(
        taskId: 'controlled_123',
        tier: 'Tier 0',
        status: 'ready',
        directImageUrl: 'https://example.com/controlled.png',
      ),
      failure: null,
    );
  }

  @override
  Future<StudioResult<PromptCompileModel>> compileChatDelta({
    required String basePrompt,
    required String userInstruction,
    int turnCount = 1,
    String aiEngine = 'groq',
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<String>> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
  }) async => (data: 'task_1', failure: null);

  @override
  Future<StudioResult<String>> removeBackground({required String imageUrl}) async =>
      (data: 'https://example.com/cutout.png', failure: null);

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) => null;

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

  group('Studio Loading Lifecycle, Task Mutual Exclusion, and Reset Tests', () {
    late ShellController shellController;
    late StudioController studioController;
    late MockControlledStudioRepository repository;

    setUp(() {
      Get.reset();
      shellController = Get.put(ShellController());
      Get.put(LibraryController());
      repository = MockControlledStudioRepository();
      studioController = Get.put(StudioController(repository: repository));
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('While loading is in progress: isBusy is true, controls lock, and no secondary tasks execute', (tester) async {
      repository.completer = Completer<GenerationDispatchModel>();

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: CreationStudioView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      studioController.promptController.text = 'Cyberpunk futuristic skyline';

      // 1. Start generation in background
      final genFuture = studioController.generateVisual();
      await tester.pump();

      // 2. Verify loading state is actively in progress
      expect(studioController.isGenerating.value, isTrue);
      expect(studioController.isBusy, isTrue);
      expect(studioController.generationProgress.value, greaterThan(0));
      expect(studioController.generationPhase.value, isNotEmpty);

      // 3. Verify interactive controls lock (AbsorbPointer is absorbing)
      final absorbPointers = tester.widgetList<AbsorbPointer>(find.byType(AbsorbPointer));
      expect(absorbPointers.any((w) => w.absorbing), isTrue);

      // 4. Verify no secondary task can execute during loading
      // E.g., changing model or aspect ratio is blocked by isBusy
      expect(studioController.selectedModel.value, 'flux');
      studioController.setModel('chatgpt');
      expect(studioController.selectedModel.value, 'flux',
          reason: 'Model selection must be blocked while studio is busy');

      // Tapping enhance during generation is blocked
      await studioController.enhancePrompt();
      expect(studioController.isEnhancing.value, isFalse);

      // 5. Complete the generation
      repository.completer!.complete(const GenerationDispatchModel(
        taskId: 'controlled_123',
        tier: 'Tier 0',
        status: 'ready',
        directImageUrl: 'https://example.com/controlled.png',
      ));
      await genFuture;
      await tester.pumpAndSettle();

      // 6. Verify loading state is cleanly RESET on success
      expect(studioController.isGenerating.value, isFalse);
      expect(studioController.isBusy, isFalse);
      expect(studioController.generationProgress.value, 0, reason: 'Progress must reset to 0 after success');
      expect(studioController.generationPhase.value, '', reason: 'Phase message must reset after success');
    });

    testWidgets('On error: loading states are cleanly reset to 0 and UI-friendly error message is displayed', (tester) async {
      repository.shouldFail = true;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: CreationStudioView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      studioController.promptController.text = 'Very long prompt that triggers 422 validation';

      // Trigger generation
      await studioController.generateVisual();
      await tester.pumpAndSettle();

      // 1. Verify loading state is cleanly RESET on failure
      expect(studioController.isGenerating.value, isFalse);
      expect(studioController.isBusy, isFalse);
      expect(studioController.generationProgress.value, 0, reason: 'Progress must reset to 0 on failure');
      expect(studioController.generationPhase.value, '', reason: 'Phase must reset on failure');

      // 2. Credits must be refunded
      expect(shellController.userCredits.value, 500.0);

      // 3. UI Friendly error message is rendered
      expect(find.text('Generation Request Failed'), findsOneWidget);
      expect(find.textContaining('Your prompt exceeds the maximum length limit'), findsOneWidget);
    });
  });
}
