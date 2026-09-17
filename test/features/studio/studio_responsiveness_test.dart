import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/creation_studio_view.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_model_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_prompt_engine_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_advanced_settings_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
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
  });

  tearDown(() {
    Get.reset();
  });

  final viewports = <String, Size>{
    'Compact (320x568)': const Size(320, 568),
    'Standard Android (360x640)': const Size(360, 640),
    'iPhone Standard (390x844)': const Size(390, 844),
    'iPhone Pro Max (430x932)': const Size(430, 932),
    'Tablet (600x1024)': const Size(600, 1024),
  };

  for (final entry in viewports.entries) {
    testWidgets('CreationStudioView is responsive at ${entry.key} with 0 overflows', (WidgetTester tester) async {
      tester.view.physicalSize = Size(entry.value.width * 2, entry.value.height * 2);
      tester.view.devicePixelRatio = 2.0;
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

      // Ensure key elements are visible and rendered without errors
      expect(find.byType(CreationStudioView), findsOneWidget);
      expect(find.text(AppStrings.studioTitle), findsOneWidget);
      expect(find.text('FLUX.1 Pro'), findsOneWidget);
    });
  }

  testWidgets('Modular bottom sheets render cleanly without overflow', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => GetMaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => StudioModelSheet.show(context),
                    child: const Text('Open Models'),
                  ),
                  ElevatedButton(
                    onPressed: () => StudioPromptEngineSheet.show(context),
                    child: const Text('Open Engines'),
                  ),
                  ElevatedButton(
                    onPressed: () => StudioAdvancedSettingsSheet.show(context),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Test opening model sheet
    await tester.tap(find.text('Open Models'));
    await tester.pumpAndSettle();
    expect(find.byType(StudioModelSheet), findsOneWidget);
    expect(find.text('Google Gemini'), findsOneWidget);

    // Dismiss sheet
    Get.back();
    await tester.pumpAndSettle();

    // Test opening prompt engine sheet
    await tester.tap(find.text('Open Engines'));
    await tester.pumpAndSettle();
    expect(find.byType(StudioPromptEngineSheet), findsOneWidget);
    expect(find.text('Gemini 2.5 Flash'), findsOneWidget);

    // Dismiss sheet
    Get.back();
    await tester.pumpAndSettle();

    // Test opening advanced settings sheet
    await tester.tap(find.text('Open Settings'));
    await tester.pumpAndSettle();
    expect(find.byType(StudioAdvancedSettingsSheet), findsOneWidget);
    expect(find.text(AppStrings.studioControls), findsOneWidget);
  });
}
