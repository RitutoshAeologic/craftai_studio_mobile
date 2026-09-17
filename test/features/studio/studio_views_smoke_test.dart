import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/creation_studio_view.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/prompt_chat_copilot_view.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/prompt_chat_copilot_controller.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_compile_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';

class MockStudioRepository implements IStudioRepository {
  @override
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'groq',
  }) async {
    return (
      data: const PromptExpandModel(
        masterPrompt: 'Expanded test prompt',
        negativePrompt: 'blurry',
        modelUsed: 'mock-engine',
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
    return (
      data: const PromptCompileModel(
        compiledPrompt: 'Compiled test prompt',
        addedTags: ['lighting'],
        removedTags: [],
        suggestedChips: ['Add Rain'],
        modelUsed: 'mock-engine',
      ),
      failure: null,
    );
  }

  @override
  Future<StudioResult<String>> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
  }) async {
    return (data: 'task_mock_123', failure: null);
  }

  @override
  Future<StudioResult<String>> removeBackground({required String imageUrl}) async {
    return (data: 'https://example.com/cutout.png', failure: null);
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
        taskId: 'task_mock_123',
        tier: 'Tier 0',
        status: 'ready',
        directImageUrl: 'https://example.com/test.png',
      ),
      failure: null,
    );
  }

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) {
    onProgress(100, 'COMPLETED', 'Done');
    return null;
  }
}

void main() {
  setUp(() {
    Get.reset();
    Get.put<IStudioRepository>(MockStudioRepository());
    Get.put<ShellController>(ShellController());
    Get.put<StudioController>(StudioController(repository: MockStudioRepository()));
    Get.put<PromptChatCopilotController>(PromptChatCopilotController(repository: MockStudioRepository()));
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('CreationStudioView renders without Obx or widget build exceptions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => const GetMaterialApp(
          home: Scaffold(
            body: CreationStudioView(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify critical studio UI controls rendered cleanly
    expect(find.byType(CreationStudioView), findsOneWidget);
    expect(find.text(AppStrings.studioTitle), findsOneWidget);
    expect(find.text('Gemini'), findsOneWidget);
    expect(find.text('FLUX.1 Pro'), findsOneWidget);
  });

  testWidgets('PromptChatCopilotView renders without Obx or widget build exceptions', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => const GetMaterialApp(
          home: PromptChatCopilotView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PromptChatCopilotView), findsOneWidget);
  });
}
