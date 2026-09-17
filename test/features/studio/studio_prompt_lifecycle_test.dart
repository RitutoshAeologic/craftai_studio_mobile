import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_prompt_inspector_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_compile_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';

class MockLifecycleStudioRepository implements IStudioRepository {
  @override
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'gemini',
  }) async {
    return (
      data: const PromptExpandModel(
        masterPrompt: 'Refined visual masterpiece anime clouds, 8K',
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
        taskId: 'gen_test_123',
        tier: 'Tier 0 (FLUX.1-schnell)',
        status: 'ready',
        directImageUrl: 'https://example.com/test.png',
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
  }) async {
    return (data: null, failure: null);
  }

  @override
  Future<StudioResult<String>> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
  }) async {
    return (data: 'task_123', failure: null);
  }

  @override
  Future<StudioResult<String>> removeBackground({required String imageUrl}) async {
    return (data: 'https://example.com/cutout.png', failure: null);
  }

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) {
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Prompt Lifecycle Transparency & Observability Tests', () {
    late StudioController studioController;

    setUp(() {
      Get.reset();
      Get.put(ShellController());
      Get.put(LibraryController());
      studioController = Get.put(
        StudioController(repository: MockLifecycleStudioRepository()),
      );
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Tracks What User Typed, Gemini Refined, Sent to Engine, and Visible in UI', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: Scaffold(body: SizedBox()),
          ),
        ),
      );

      // 1. User types original draft
      const userDraft = 'Makoto Shinkai clouds floating islands';
      studioController.promptController.text = userDraft;

      // 2. User taps Enhance
      await studioController.enhancePrompt();
      await tester.pumpAndSettle();

      // Assert Stage 1: What User Typed is captured
      expect(studioController.userTypedPrompt.value, userDraft);

      // Assert Stage 2: What Gemini Refined is captured in background
      expect(studioController.geminiRefinedPrompt.value, 'Refined visual masterpiece anime clouds, 8K');
      expect(studioController.geminiNegativePrompt.value, 'blurry, distorted');
      expect(studioController.geminiModelUsed.value, 'google/gemini-2.5-flash (Live AI)');

      // Assert Option A: What User Sees in UI remains clean!
      expect(studioController.promptController.text, userDraft);
      expect(studioController.isPromptEnhanced, isTrue);

      // 3. Trigger generation while enhanced
      await studioController.generateVisual();
      await tester.pumpAndSettle();

      // Assert Stage 3: What Sent for Generation is the secret Gemini master recipe!
      expect(studioController.lastDispatchedPrompt.value, 'Refined visual masterpiece anime clouds, 8K');
      expect(studioController.lastDispatchedModel.value, 'flux');
      expect(studioController.lastDispatchedDimensions.value, '1024x1024 (1:1)');

      // Assert UI text still remains clean user draft
      expect(studioController.promptController.text, userDraft);

      // 4. Test Disarm Enhancement
      studioController.clearEnhancement();
      expect(studioController.isPromptEnhanced, isFalse);

      // Re-arm for inspector testing
      await studioController.enhancePrompt();
      await tester.pumpAndSettle();

      // 5. Verify StudioPromptInspectorSheet mounts cleanly
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => GetMaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => studioController.openPromptInspectorSheet(context),
                  child: const Text('Open Inspector'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Inspector'));
      await tester.pumpAndSettle();

      expect(find.byType(StudioPromptInspectorSheet), findsOneWidget);
      expect(find.text('Prompt Lifecycle Inspector'), findsOneWidget);
      expect(find.text('What You Typed (Raw Draft)'), findsOneWidget);
      expect(find.text('What Gemini Refined (AI Master)'), findsOneWidget);
      expect(find.text('Sent to Image AI (FLUX.1 Engine)'), findsOneWidget);
      expect(find.text('What You See in Studio & Library'), findsOneWidget);

      // Settle all queued snackbars and their dismissal animations
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
      }
    });
  });
}
