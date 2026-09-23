import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_error_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/domain/failures/studio_failure.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_compile_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import '../../mocks/fake_studio_repository.dart';

class FailingStudioRepository extends FakeStudioRepository {
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
      data: null,
      failure: const StudioNetworkFailure(
        'Cannot connect to local backend (127.0.0.1:8000). On physical Android devices, run "adb reverse tcp:8000 tcp:8000".',
      ),
    );
  }

  @override
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'groq',
  }) async {
    return (data: null, failure: const StudioNetworkFailure());
  }

  @override
  Future<StudioResult<PromptCompileModel>> compileChatDelta({
    required String basePrompt,
    required String userInstruction,
    int turnCount = 1,
    String aiEngine = 'groq',
  }) async {
    return (data: null, failure: const StudioNetworkFailure());
  }

  @override
  Future<StudioResult<String>> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
  }) async {
    return (data: null, failure: const StudioNetworkFailure());
  }

  @override
  Future<StudioResult<String>> removeBackground({required String imageUrl}) async {
    return (data: null, failure: const StudioNetworkFailure());
  }

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) {
    return null;
  }

  @override
  Future<StudioResult<RemixSessionModel>> createRemixSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
    double styleWeight = 0.60,
  }) async => (data: null, failure: const StudioNetworkFailure());

  @override
  Future<StudioResult<RemixSessionModel>> getRemixSession({
    required String sessionId,
  }) async => (data: null, failure: const StudioNetworkFailure());

  @override
  Future<StudioResult<RemixChatTurnResult>> sendRemixChatMessage({
    required String sessionId,
    required String userInstruction,
    String aiModel = 'groq',
    double? styleWeight,
  }) async => (data: null, failure: const StudioNetworkFailure());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Studio Generation Error Handling & Credit Refund Tests', () {
    late ShellController shellController;
    late StudioController studioController;

    setUp(() {
      Get.reset();
      shellController = Get.put(ShellController());
      Get.put(LibraryController());
      studioController = Get.put(
        StudioController(repository: FailingStudioRepository()),
      );
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Credits are refunded and user stays on Studio tab when backend fails', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: Scaffold(body: SizedBox()),
          ),
        ),
      );

      // Initial state: 500 Credits, on Studio tab (index 1)
      shellController.switchTab(1);
      expect(shellController.userCredits.value, 500.0);
      expect(shellController.currentIndex.value, 1);

      // Set prompt
      studioController.promptController.text = 'Cyberpunk cityscape in neon rain';

      // Trigger generation
      await studioController.generateVisual();
      await tester.pumpAndSettle();

      // Verification:
      // 1. Credits MUST be fully refunded back to 500
      expect(
        shellController.userCredits.value,
        500.0,
        reason: 'Optimistically deducted credits must be restored on generation failure',
      );

      // 2. User MUST NOT be moved to Library tab (tab index 3)
      expect(
        shellController.currentIndex.value,
        1,
        reason: 'User must stay on Studio canvas and never be kicked to Library on failure',
      );

      // 3. StudioController is no longer generating
      expect(studioController.isGenerating.value, isFalse);

      // 4. StudioErrorSheet modal was rendered
      expect(find.byType(StudioErrorSheet), findsOneWidget);
      expect(find.text('Server Connection Failed'), findsOneWidget);
      expect(find.textContaining('adb reverse tcp:8000 tcp:8000'), findsOneWidget);
      expect(find.textContaining('Credits have been refunded'), findsOneWidget);
    });
  });
}
