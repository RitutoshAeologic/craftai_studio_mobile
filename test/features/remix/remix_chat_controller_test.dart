import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
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
import '../../mocks/fake_studio_repository.dart';

class MockRemixStudioRepository extends FakeStudioRepository {
  bool shouldFailSessionCreation = false;
  bool shouldFailChatMessage = false;
  bool shouldFailGeneration = false;
  int sendChatMessageCalls = 0;
  String? lastUserInstruction;

  @override
  Future<StudioResult<RemixSessionModel>> createRemixSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
    double styleWeight = 0.60,
  }) async {
    if (shouldFailSessionCreation) {
      return (data: null, failure: null);
    }
    return (
      data: RemixSessionModel(
        id: 'sess_test_123',
        anchorImageUrl: anchorImageUrl,
        sourceType: sourceType,
        remixedFromPromptId: remixedFromPromptId,
        currentPrompt: initialPrompt ?? 'Initial test prompt',
        styleWeight: styleWeight,
        turnCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          RemixMessageModel(
            id: 'msg_welcome_test',
            sessionId: 'sess_test_123',
            role: 'assistant',
            content: 'Welcome to Remix Lab!',
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

    if (shouldFailChatMessage) {
      return (data: null, failure: null);
    }

    return (
      data: RemixChatTurnResult(
        sessionId: sessionId,
        compiledPrompt: 'Compiled remix prompt with $userInstruction',
        userMessage: RemixMessageModel(
          id: 'msg_user_server',
          sessionId: sessionId,
          role: 'user',
          content: userInstruction,
          createdAt: DateTime.now(),
        ),
        assistantMessage: RemixMessageModel(
          id: 'msg_assistant_server',
          sessionId: sessionId,
          role: 'assistant',
          content: 'Applied $userInstruction to the anchor artwork.',
          diffAdded: [userInstruction],
          suggestedChips: const ['+ Neon Glow', '+ Cyber Fog'],
          modelUsed: 'Groq LPU (qwen/qwen3.8-27b)',
          createdAt: DateTime.now(),
        ),
        turnCount: 1,
        suggestedChips: const ['+ Neon Glow', '+ Cyber Fog'],
        modelUsed: 'Groq LPU (qwen/qwen3.8-27b)',
        latencyMs: 180,
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
    if (shouldFailGeneration) {
      return (data: null, failure: null);
    }
    return (
      data: const GenerationDispatchModel(
        taskId: 'task_remix_synth_1',
        tier: 'Tier 0',
        status: 'ready',
        directImageUrl: 'https://example.com/remixed_variation.png',
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

  group('RemixChatController Tests', () {
    late MockRemixStudioRepository mockRepo;
    late ShellController shellController;
    late LibraryController libraryController;
    late RemixChatController remixController;

    setUp(() {
      Get.reset();
      mockRepo = MockRemixStudioRepository();
      Get.put<IStudioRepository>(mockRepo);
      shellController = Get.put(ShellController());
      shellController.userCredits.value = 10.0;
      libraryController = Get.put(LibraryController());
    });

    tearDown(() {
      Get.reset();
    });

    test('Initializes session successfully from initialArgs and loads welcome message', () async {
      remixController = Get.put(RemixChatController(
        repository: mockRepo,
        initialArgs: {
          'anchorImageUrl': 'https://example.com/anchor.png',
          'authorName': 'Artist One',
          'royaltyPercent': 40,
          'sourceType': 'explore',
          'initialPrompt': 'Base cyberpunk portrait',
        },
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remixController.anchorImageUrl.value, 'https://example.com/anchor.png');
      expect(remixController.authorName.value, 'Artist One');
      expect(remixController.authorRoyaltyPercent.value, 40);
      expect(remixController.session.value?.id, 'sess_test_123');
      expect(remixController.messages.length, 1);
      expect(remixController.messages.first.content, 'Welcome to Remix Lab!');
      expect(remixController.isInitializing.value, isFalse);
    });

    test('Falls back gracefully to local session if repository fails', () async {
      mockRepo.shouldFailSessionCreation = true;
      remixController = Get.put(RemixChatController(
        repository: mockRepo,
        initialArgs: {
          'anchorImageUrl': 'https://example.com/anchor_offline.png',
        },
      ));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(remixController.session.value, isNotNull);
      expect(remixController.session.value!.id.startsWith('sess_local_'), isTrue);
      expect(remixController.messages.length, 1);
      expect(remixController.messages.first.role, 'assistant');
      expect(remixController.isInitializing.value, isFalse);
    });

    test('setStyleWeight clamps between 0.10 and 1.00 and ignores updates while sending', () {
      remixController = Get.put(RemixChatController(repository: mockRepo));

      remixController.setStyleWeight(0.90);
      expect(remixController.styleWeight.value, 0.90);

      remixController.setStyleWeight(1.50);
      expect(remixController.styleWeight.value, 1.00);

      remixController.setStyleWeight(-0.20);
      expect(remixController.styleWeight.value, 0.10);

      remixController.isSending.value = true;
      remixController.setStyleWeight(0.50);
      expect(remixController.styleWeight.value, 0.10); // remains unchanged
    });

    test('addModifierTag correctly appends comma-separated tags to inputController', () {
      remixController = Get.put(RemixChatController(repository: mockRepo));

      remixController.addModifierTag('+ Cyberpunk Neon');
      expect(remixController.inputController.text, 'Cyberpunk Neon');

      remixController.addModifierTag('+ Studio Ghibli Anime');
      expect(remixController.inputController.text, 'Cyberpunk Neon, Studio Ghibli Anime');
    });

    test('sendInstruction ignores empty or whitespace-only inputs', () async {
      remixController = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final initialMsgCount = remixController.messages.length;
      await remixController.sendInstruction('   ');

      expect(mockRepo.sendChatMessageCalls, 0);
      expect(remixController.messages.length, initialMsgCount);
      expect(remixController.turnCount.value, 0);
    });

    test('sendInstruction enforces max 500 characters validation limit', () async {
      remixController = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final longInstruction = 'A' * 501;
      await remixController.sendInstruction(longInstruction);

      expect(mockRepo.sendChatMessageCalls, 0);
      expect(remixController.turnCount.value, 0);
    });

    test('sendInstruction enforces 5-turn refinement cap', () async {
      remixController = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      remixController.turnCount.value = 5;
      await remixController.sendInstruction('Add moody sunset');

      expect(mockRepo.sendChatMessageCalls, 0);
    });

    test('sendInstruction optimistic UI update (0ms) and replaces with server confirmation', () async {
      remixController = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await remixController.sendInstruction('Make it cinematic cyberpunk with rain');

      expect(mockRepo.sendChatMessageCalls, 1);
      expect(mockRepo.lastUserInstruction, 'Make it cinematic cyberpunk with rain');
      expect(remixController.turnCount.value, 1);
      expect(remixController.currentCompiledPrompt.value, 'Compiled remix prompt with Make it cinematic cyberpunk with rain');
      expect(remixController.suggestedChips, contains('+ Neon Glow'));

      // Check messages: 1 initial welcome + 1 user message + 1 assistant message = 3
      expect(remixController.messages.length, 3);
      expect(remixController.messages[1].role, 'user');
      expect(remixController.messages[1].content, 'Make it cinematic cyberpunk with rain');
      expect(remixController.messages[2].role, 'assistant');
      expect(remixController.messages[2].content, contains('Applied Make it cinematic cyberpunk with rain'));
    });

    test('sendInstruction handles offline fallback when server call fails', () async {
      mockRepo.shouldFailChatMessage = true;
      remixController = Get.put(RemixChatController(repository: mockRepo));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await remixController.sendInstruction('Dark neon rain');

      expect(mockRepo.sendChatMessageCalls, 1);
      expect(remixController.currentCompiledPrompt.value, contains('Dark neon rain'));
      expect(remixController.messages.last.role, 'assistant');
      expect(remixController.messages.last.content, contains('Applied: "Dark neon rain"'));
    });

    test('generateRemix checks credit pre-check and blocks when user credits < 1.0', () async {
      shellController.userCredits.value = 0.5;
      remixController = Get.put(RemixChatController(repository: mockRepo));

      await remixController.generateRemix();

      expect(remixController.isGenerating.value, isFalse);
      expect(remixController.lastGeneratedImageUrl.value, isNull);
    });

    test('generateRemix dispatches generation, deducts credit, and saves to Library', () async {
      shellController.userCredits.value = 5.0;
      remixController = Get.put(RemixChatController(
        repository: mockRepo,
        initialArgs: {
          'anchorImageUrl': 'https://example.com/test_anchor.png',
        },
      ));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      await remixController.generateRemix();

      expect(shellController.userCredits.value, 4.0); // 1.0 deducted
      expect(remixController.isGenerating.value, isFalse);
      expect(remixController.lastGeneratedImageUrl.value, 'https://example.com/remixed_variation.png');
      expect(libraryController.myCreations.any((c) => c.previewUrl == 'https://example.com/remixed_variation.png'), isTrue);
      expect(remixController.messages.last.generatedImageUrl, 'https://example.com/remixed_variation.png');
    });
  });
}
