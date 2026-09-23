import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/remix/controllers/remix_chat_controller.dart';
import 'package:craftai_studio_mobile/features/remix/domain/models/remix_session_model.dart';
import 'package:craftai_studio_mobile/features/remix/domain/models/remix_message_model.dart';
import 'package:craftai_studio_mobile/features/remix/domain/models/remix_chat_turn_result.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_compile_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/shared/widgets/before_after_slider.dart';
import '../../mocks/fake_studio_repository.dart';

class MockEdgeCaseStudioRepository extends FakeStudioRepository {
  int sendChatMessageCalls = 0;
  int dispatchGenerationCalls = 0;
  String? lastUserInstruction;
  Completer<StudioResult<RemixChatTurnResult>>? chatCompleter;
  Completer<StudioResult<GenerationDispatchModel>>? genCompleter;
  void Function(int progress, String status, String message)? progressCallback;

  @override
  Future<StudioResult<RemixSessionModel>> createRemixSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
    double styleWeight = 0.60,
  }) async {
    return (
      data: RemixSessionModel(
        id: 'sess_edge_case',
        anchorImageUrl: anchorImageUrl,
        sourceType: sourceType,
        remixedFromPromptId: remixedFromPromptId,
        currentPrompt: initialPrompt ?? 'Initial master prompt',
        styleWeight: styleWeight,
        turnCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          RemixMessageModel(
            id: 'msg_welcome_edge',
            sessionId: 'sess_edge_case',
            role: 'assistant',
            content: 'Visual anchor locked. How would you like to remix it?',
            createdAt: DateTime.now(),
          ),
        ],
      ),
      failure: null,
    );
  }

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
  }) async {
    sendChatMessageCalls++;
    lastUserInstruction = userInstruction;

    if (chatCompleter != null) {
      return chatCompleter!.future;
    }

    return (
      data: RemixChatTurnResult(
        sessionId: sessionId,
        compiledPrompt: 'Refined prompt including $userInstruction',
        userMessage: RemixMessageModel(
          id: 'msg_user_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: sessionId,
          role: 'user',
          content: userInstruction,
          createdAt: DateTime.now(),
        ),
        assistantMessage: RemixMessageModel(
          id: 'msg_assistant_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: sessionId,
          role: 'assistant',
          content: 'Applied modifications for "$userInstruction".',
          diffAdded: [userInstruction],
          suggestedChips: const ['+ Neon Glow', '+ Film Grain'],
          modelUsed: 'Groq LPU',
          createdAt: DateTime.now(),
        ),
        turnCount: 1,
        suggestedChips: const ['+ Neon Glow', '+ Film Grain'],
        modelUsed: 'Groq LPU',
        latencyMs: 120,
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
    dispatchGenerationCalls++;

    if (genCompleter != null) {
      return genCompleter!.future;
    }

    return (
      data: const GenerationDispatchModel(
        taskId: 'task_async_progress_1',
        tier: 'Tier 0',
        status: 'queued',
        directImageUrl: '', // Empty direct url to trigger progress stream listener
      ),
      failure: null,
    );
  }

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) {
    progressCallback = onProgress;
    return null;
  }

  @override
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'groq',
  }) async => (data: null, failure: null);

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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Remix QA Edge Cases & Adversarial Verification', () {
    late MockEdgeCaseStudioRepository mockRepo;
    late ShellController shellController;
    late RemixChatController controller;

    setUp(() {
      Get.reset();
      mockRepo = MockEdgeCaseStudioRepository();
      Get.put<IStudioRepository>(mockRepo);
      shellController = Get.put(ShellController());
      shellController.userCredits.value = 10.0;
      Get.put(LibraryController());
    });

    tearDown(() {
      Get.reset();
    });

    // ─────────────────────────────────────────────────────────
    // 1. INPUT VALIDATION BOUNDARIES & WEIRD INPUTS
    // ─────────────────────────────────────────────────────────
    test('QA Edge Case: Multi-line whitespace, tabs, carriage returns are cleanly rejected', () async {
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final initialMsgCount = controller.messages.length;

      await controller.sendInstruction('   \n\n\t\r\n   ');

      expect(mockRepo.sendChatMessageCalls, 0);
      expect(controller.messages.length, initialMsgCount);
      expect(controller.turnCount.value, 0);
    });

    test('QA Edge Case: Minimum boundary (exactly 1 char) is accepted and dispatched', () async {
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await controller.sendInstruction('A');

      expect(mockRepo.sendChatMessageCalls, 1);
      expect(mockRepo.lastUserInstruction, 'A');
      expect(controller.turnCount.value, 1);
    });

    test('QA Edge Case: Maximum boundary (exactly 500 chars) is accepted and dispatched', () async {
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final exact500 = 'x' * 500;
      await controller.sendInstruction(exact500);

      expect(mockRepo.sendChatMessageCalls, 1);
      expect(mockRepo.lastUserInstruction, exact500);
      expect(controller.turnCount.value, 1);
    });

    test('QA Edge Case: Off-by-one boundary (501 chars) is blocked without network call', () async {
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final offByOne501 = 'x' * 501;
      await controller.sendInstruction(offByOne501);

      expect(mockRepo.sendChatMessageCalls, 0);
      expect(controller.turnCount.value, 0);
    });

    test('QA Edge Case: Emojis, XSS payloads, and international scripts execute safely', () async {
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      const maliciousPayload = "<script>alert('xss')</script> 🤖 🔥 \"quoted\" & 'single' नमस्ते 日本語";
      await controller.sendInstruction(maliciousPayload);

      expect(mockRepo.sendChatMessageCalls, 1);
      expect(mockRepo.lastUserInstruction, maliciousPayload);
      expect(controller.messages.any((m) => m.content == maliciousPayload), isTrue);
    });

    // ─────────────────────────────────────────────────────────
    // 2. CONCURRENCY, DOUBLE-TAP SPAM & MUTUAL EXCLUSION
    // ─────────────────────────────────────────────────────────
    test('QA Edge Case: Double-tap spam on sendInstruction triggers exactly 1 network call', () async {
      mockRepo.chatCompleter = Completer();
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Fire 3 simultaneous send calls before the first one completes
      final f1 = controller.sendInstruction('First Tap');
      final f2 = controller.sendInstruction('Second Rapid Tap');
      final f3 = controller.sendInstruction('Third Rapid Tap');

      expect(controller.isSending.value, isTrue);
      expect(mockRepo.sendChatMessageCalls, 1);

      // Complete the in-flight request
      mockRepo.chatCompleter!.complete((
        data: RemixChatTurnResult(
          sessionId: 'sess_edge_case',
          compiledPrompt: 'Compiled First Tap',
          userMessage: RemixMessageModel(
            id: 'u1',
            sessionId: 'sess_edge_case',
            role: 'user',
            content: 'First Tap',
            createdAt: DateTime.now(),
          ),
          assistantMessage: RemixMessageModel(
            id: 'a1',
            sessionId: 'sess_edge_case',
            role: 'assistant',
            content: 'Applied First Tap',
            createdAt: DateTime.now(),
          ),
          turnCount: 1,
          suggestedChips: const [],
          modelUsed: 'groq',
          latencyMs: 100,
        ),
        failure: null,
      ));

      await Future.wait([f1, f2, f3]);

      expect(mockRepo.sendChatMessageCalls, 1);
      expect(controller.turnCount.value, 1);
      expect(controller.isSending.value, isFalse);
    });

    test('QA Edge Case: Double-tap spam on generateRemix does not double-charge credits', () async {
      mockRepo.genCompleter = Completer();
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      shellController.userCredits.value = 5.0;

      // Tap generateRemix twice rapidly
      final g1 = controller.generateRemix();
      final g2 = controller.generateRemix();

      expect(mockRepo.dispatchGenerationCalls, 1);
      expect(controller.isGenerating.value, isTrue);

      // Resolve generation
      mockRepo.genCompleter!.complete((
        data: const GenerationDispatchModel(
          taskId: 'task_double_tap_safe',
          tier: 'Tier 0',
          status: 'ready',
          directImageUrl: 'https://example.com/unique.png',
        ),
        failure: null,
      ));

      await Future.wait([g1, g2]);

      // Exactly 1.0 credit deducted, NOT 2.0!
      expect(shellController.userCredits.value, 4.0);
      expect(mockRepo.dispatchGenerationCalls, 1);
      expect(controller.isGenerating.value, isFalse);
    });

    test('QA Edge Case: generateRemix is locked while sendInstruction is in flight', () async {
      mockRepo.chatCompleter = Completer();
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      unawaited(controller.sendInstruction('Refinement in progress'));
      expect(controller.isSending.value, isTrue);

      // Attempt to generate while prompt is compiling
      await controller.generateRemix();

      expect(mockRepo.dispatchGenerationCalls, 0);
      expect(controller.isGenerating.value, isFalse);
    });

    test('QA Edge Case: sendInstruction is locked while generateRemix is in flight', () async {
      mockRepo.genCompleter = Completer();
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      unawaited(controller.generateRemix());
      expect(controller.isGenerating.value, isTrue);

      // Attempt to send prompt tweak while image is synthesizing
      await controller.sendInstruction('Tweak while rendering');

      expect(mockRepo.sendChatMessageCalls, 0);
    });

    // ─────────────────────────────────────────────────────────
    // 3. 5-TURN LIMIT HARD CEILING
    // ─────────────────────────────────────────────────────────
    test('QA Edge Case: Turn count reaching exactly 5 disables further turns cleanly', () async {
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      for (int i = 1; i <= 5; i++) {
        await controller.sendInstruction('Turn instruction #$i');
        expect(controller.turnCount.value, i);
      }

      expect(mockRepo.sendChatMessageCalls, 5);

      // Attempt Turn 6
      await controller.sendInstruction('Attempting turn 6 beyond limit');

      expect(mockRepo.sendChatMessageCalls, 5); // Still 5, never dispatched!
      expect(controller.turnCount.value, 5);
    });

    // ─────────────────────────────────────────────────────────
    // 4. WALLET & CREDIT BOUNDARY CONDITIONS
    // ─────────────────────────────────────────────────────────
    test('QA Edge Case: Exact credit boundary 1.0 succeeds and drops wallet to 0.0', () async {
      shellController.userCredits.value = 1.0;
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await controller.generateRemix();

      expect(mockRepo.dispatchGenerationCalls, 1);
      expect(shellController.userCredits.value, 0.0);
    });

    test('QA Edge Case: Boundary 0.99 credits is blocked without dispatching', () async {
      shellController.userCredits.value = 0.99;
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await controller.generateRemix();

      expect(mockRepo.dispatchGenerationCalls, 0);
      expect(shellController.userCredits.value, 0.99); // Untouched
      expect(controller.isGenerating.value, isFalse);
    });

    test('QA Edge Case: Task failure during generation stream triggers 1.0 credit refund', () async {
      shellController.userCredits.value = 5.0;
      controller = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Trigger generation with async progress
      unawaited(controller.generateRemix());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(shellController.userCredits.value, 4.0); // Optimistically deducted
      expect(controller.isGenerating.value, isTrue);
      expect(mockRepo.progressCallback, isNotNull);

      // Backend sends failure event
      mockRepo.progressCallback!(50, 'failed', 'CUDA GPU out of memory');

      expect(shellController.userCredits.value, 5.0); // Refunded back!
      expect(controller.isGenerating.value, isFalse);
      expect(controller.generationProgress.value, 0);
    });

    // ─────────────────────────────────────────────────────────
    // 5. INTENSITY CLAMPING BOUNDARIES
    // ─────────────────────────────────────────────────────────
    test('QA Edge Case: setStyleWeight clamps extreme out-of-bound floats', () {
      controller = Get.put(RemixChatController(repository: mockRepo));

      controller.setStyleWeight(-999.0);
      expect(controller.styleWeight.value, 0.10);

      controller.setStyleWeight(999.0);
      expect(controller.styleWeight.value, 1.00);

      controller.setStyleWeight(0.60);
      expect(controller.styleWeight.value, 0.60);
    });

    // ─────────────────────────────────────────────────────────
    // 6. BEFORE/AFTER SLIDER WIDGET INTEGRITY
    // ─────────────────────────────────────────────────────────
    testWidgets('QA Edge Case: BeforeAfterSlider renders and handles drag boundary without overflow', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: BeforeAfterSlider(
                  beforeImageUrl: 'https://example.com/before.png',
                  afterImageUrl: 'https://example.com/after.png',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BeforeAfterSlider), findsOneWidget);
      expect(find.text('ANCHOR'), findsOneWidget);
      expect(find.text('REMIX'), findsOneWidget);
      expect(find.text('Drag divider or hold to view original'), findsOneWidget);

      // Perform horizontal drag to leftmost boundary
      await tester.drag(find.byType(BeforeAfterSlider), const Offset(-200, 0));
      await tester.pump();

      // Perform horizontal drag to rightmost boundary
      await tester.drag(find.byType(BeforeAfterSlider), const Offset(400, 0));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}
