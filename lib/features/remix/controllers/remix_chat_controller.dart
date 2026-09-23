import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/services/network_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/data/repositories/studio_repository_impl.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import '../domain/models/remix_session_model.dart';
import '../domain/models/remix_message_model.dart';
import '../domain/failures/remix_failure.dart';

/// [RemixChatController] drives the dedicated, low-latency conversational
/// Remix Assistant. Implements sub-350ms optimistic UI updates, strict input
/// validation (1-500 chars, 5-turn cap), double-tap guards, and automatic
/// creator royalty attribution per prod.md Flow D and rules.md §6.
class RemixChatController extends GetxController {
  final IStudioRepository _repository;
  final Map<String, dynamic>? initialArgs;

  RemixChatController({
    IStudioRepository? repository,
    this.initialArgs,
  }) : _repository = repository ??
            (Get.isRegistered<IStudioRepository>()
                ? Get.find<IStudioRepository>()
                : StudioRepositoryImpl());

  final TextEditingController inputController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  /// Active Remix Session state
  final Rxn<RemixSessionModel> session = Rxn<RemixSessionModel>();
  final RxList<RemixMessageModel> messages = <RemixMessageModel>[].obs;

  /// Prompt & Guidance State
  final RxString currentCompiledPrompt = ''.obs;
  final RxDouble styleWeight = 0.60.obs;
  final RxInt turnCount = 0.obs;
  final RxInt promptLength = 0.obs;

  /// Attribution & Source Info
  final RxString anchorImageUrl = ''.obs;
  final RxString authorName = ''.obs;
  final RxInt authorRoyaltyPercent = 40.obs;

  /// Loading & Task Flags
  final RxBool isInitializing = true.obs;
  final RxBool isSending = false.obs;
  final RxBool isGenerating = false.obs;
  final RxInt generationProgress = 0.obs;
  final RxString generationPhase = ''.obs;
  final RxnString lastGeneratedImageUrl = RxnString();

  /// Curated Quick Aesthetic Modifier Chips
  final RxList<String> suggestedChips = <String>[
    '+ Cyberpunk Neon',
    '+ Studio Ghibli Anime',
    '+ 3D Octane Render',
    '+ Dark Moody Cinematic',
    '+ Watercolor Dreamscape',
  ].obs;

  StreamSubscription? _progressSub;

  @override
  void onInit() {
    super.onInit();
    inputController.addListener(() {
      promptLength.value = inputController.text.length;
    });
    _initSessionFromArgs();
  }

  void _initSessionFromArgs() {
    final args = initialArgs ?? (Get.arguments as Map<String, dynamic>? ?? {});
    anchorImageUrl.value = args['anchorImageUrl'] as String? ??
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb';
    authorName.value = args['authorName'] as String? ?? 'Community Creator';
    authorRoyaltyPercent.value = args['royaltyPercent'] as int? ?? 40;

    final sourceType = args['sourceType'] as String? ?? 'explore';
    final remixedFromPromptId = args['remixedFromPromptId'] as String?;
    final initialPrompt = args['initialPrompt'] as String? ??
        'Preserve subject identity and visual anchor with balanced styling';

    createSession(
      anchorImageUrl: anchorImageUrl.value,
      sourceType: sourceType,
      remixedFromPromptId: remixedFromPromptId,
      initialPrompt: initialPrompt,
    );
  }

  /// Creates a new backend session and populates initial welcome guidance
  Future<void> createSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
  }) async {
    isInitializing.value = true;
    final result = await _repository.createRemixSession(
      anchorImageUrl: anchorImageUrl,
      sourceType: sourceType,
      remixedFromPromptId: remixedFromPromptId,
      initialPrompt: initialPrompt,
      styleWeight: styleWeight.value,
    );

    if (result.data != null) {
      final s = result.data!;
      session.value = s;
      currentCompiledPrompt.value = s.currentPrompt;
      styleWeight.value = s.styleWeight;
      turnCount.value = s.turnCount;
      messages.assignAll(s.messages);
      AppLogger.s('Remix session initialized: ${s.id}', tag: 'REMIX_CHAT');
    } else {
      // Local fallback session to ensure user is never blocked
      final fallbackSession = RemixSessionModel(
        id: 'sess_local_${DateTime.now().millisecondsSinceEpoch}',
        anchorImageUrl: anchorImageUrl,
        sourceType: sourceType,
        remixedFromPromptId: remixedFromPromptId,
        currentPrompt: initialPrompt ?? 'Cyberpunk visual masterpiece',
        styleWeight: styleWeight.value,
        turnCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        messages: [
          RemixMessageModel(
            id: 'msg_welcome',
            sessionId: 'local',
            role: 'assistant',
            content:
                'Reference artwork locked as visual anchor. What style, lighting, or scenario modifications would you like to apply?',
            diffAdded: const ['composition_anchor'],
            suggestedChips: suggestedChips,
            createdAt: DateTime.now(),
          ),
        ],
      );
      session.value = fallbackSession;
      currentCompiledPrompt.value = fallbackSession.currentPrompt;
      messages.assignAll(fallbackSession.messages);
    }
    isInitializing.value = false;
  }

  /// Updates transformation intensity (Subtle 0.30 • Balanced 0.60 • Bold 0.90)
  void setStyleWeight(double weight) {
    if (isSending.value || isGenerating.value) return;
    styleWeight.value = weight.clamp(0.10, 1.00);
    HapticFeedback.selectionClick();
  }

  /// Appends a quick modifier tag to the active input text
  void addModifierTag(String tag) {
    if (isSending.value || isGenerating.value) return;
    HapticFeedback.selectionClick();
    final current = inputController.text.trim();
    if (current.isEmpty) {
      inputController.text = tag.replaceFirst('+ ', '');
    } else {
      inputController.text = '$current, ${tag.replaceFirst('+ ', '')}';
    }
    inputController.selection = TextSelection.fromPosition(
      TextPosition(offset: inputController.text.length),
    );
  }

  /// Sub-second conversational prompt refinement with 0ms optimistic UI rendering
  Future<void> sendInstruction(String rawText) async {
    final clean = rawText.trim();

    // 1. Validation: non-empty check
    if (clean.isEmpty) return;

    // 2. Double-tap and concurrency guard
    if (isSending.value || isGenerating.value) {
      AppLogger.w('Send instruction blocked: Task in flight', tag: 'REMIX_CHAT');
      return;
    }

    // 3. Validation: Max 500 characters
    if (clean.length > 500) {
      _showUserError(const RemixValidationFailure(
        'Prompt instruction is too long. Please keep it under 500 characters.',
      ));
      return;
    }

    // 4. Validation: 5-turn refinement cap
    if (turnCount.value >= 5) {
      _showUserError(const RemixTurnLimitFailure());
      return;
    }

    // 5. Optimistic UI Update (0ms latency)
    HapticFeedback.lightImpact();
    isSending.value = true;
    turnCount.value++;

    final optimisticMsgId = 'opt_${DateTime.now().millisecondsSinceEpoch}';
    final userOptimisticMsg = RemixMessageModel(
      id: optimisticMsgId,
      sessionId: session.value?.id ?? 'sess_active',
      role: 'user',
      content: clean,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    messages.add(userOptimisticMsg);
    inputController.clear();
    _scrollToBottom();

    // 6. Network Dispatch to Backend Groq LPU
    final sessionId = session.value?.id ?? 'sess_active';
    final result = await _repository.sendRemixChatMessage(
      sessionId: sessionId,
      userInstruction: clean,
      aiModel: 'groq',
      styleWeight: styleWeight.value,
    );

    if (isClosed) return;

    if (result.data != null) {
      final turnResult = result.data!;
      currentCompiledPrompt.value = turnResult.compiledPrompt;

      // Replace optimistic message with confirmed server message
      final index = messages.indexWhere((m) => m.id == optimisticMsgId);
      if (index != -1) {
        messages[index] = turnResult.userMessage;
      }
      messages.add(turnResult.assistantMessage);

      if (turnResult.suggestedChips.isNotEmpty) {
        suggestedChips.assignAll(turnResult.suggestedChips);
      }
      AppLogger.s('Remix prompt refined in ${turnResult.latencyMs}ms: "${turnResult.compiledPrompt}"', tag: 'REMIX_CHAT');
    } else {
      // Graceful local compiler fallback
      final fallbackPrompt = '${currentCompiledPrompt.value}, $clean, 8k resolution, cinematic lighting, masterpiece';
      currentCompiledPrompt.value = fallbackPrompt;

      final assistantFallback = RemixMessageModel(
        id: 'msg_fallback_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: sessionId,
        role: 'assistant',
        content: 'Applied: "$clean". Prompt recipe refined for diffusion synthesis.',
        diffAdded: [clean],
        suggestedChips: suggestedChips,
        modelUsed: 'Local Fallback Engine',
        createdAt: DateTime.now(),
      );
      messages.add(assistantFallback);

      _showUserError(const RemixNetworkFailure(
        'Offline fallback active. Your prompt modification was applied locally.',
      ));
    }

    isSending.value = false;
    _scrollToBottom();
  }

  /// Synthesizes the image remix variation with wallet credit deduction & attribution
  Future<void> generateRemix() async {
    if (isGenerating.value || isSending.value) return;

    // Fast-fail if device is currently offline
    if (Get.isRegistered<NetworkService>() && !NetworkService.to.isOnline) {
      _showUserError(const RemixNetworkFailure('You are currently offline. Please reconnect to generate remixes.'));
      return;
    }

    // 1. Credit Pre-check
    final shellCtrl = Get.isRegistered<ShellController>() ? Get.find<ShellController>() : null;
    final balance = shellCtrl?.userCredits.value ?? 10.0;
    if (balance < 1.0) {
      _showUserError(const RemixInsufficientCreditsFailure());
      return;
    }

    // 2. Lock UI & trigger progress
    HapticFeedback.mediumImpact();
    isGenerating.value = true;
    generationProgress.value = 5;
    generationPhase.value = 'Preparing synthesis latents...';

    final promptToDispatch = currentCompiledPrompt.value.isNotEmpty
        ? currentCompiledPrompt.value
        : 'Remix of anchor artwork, master quality 8k, cinematic';

    AppLogger.i('Dispatching remix generation: "$promptToDispatch"', tag: 'REMIX_GEN');

    final result = await _repository.dispatchGeneration(
      prompt: promptToDispatch,
      faceReferenceUrls: [anchorImageUrl.value],
      remixedFromPromptId: session.value?.remixedFromPromptId,
      model: 'flux',
    );

    if (result.data != null) {
      final dispatchData = result.data!;
      final taskId = dispatchData.taskId;

      // Deduct credit optimistically
      shellCtrl?.deductCredits(1.0);

      if (dispatchData.directImageUrl.isNotEmpty) {
        _onGenerationCompleted(dispatchData.directImageUrl);
      } else {
        _progressSub?.cancel();
        _progressSub = _repository.listenToGenerationProgress(
          taskId: taskId,
          onProgress: (progress, status, message) {
            generationProgress.value = progress;
            generationPhase.value = message.isNotEmpty ? message : 'Diffusing remix latents ($progress%)...';
            if (progress >= 100 && status == 'completed') {
              _onGenerationCompleted(dispatchData.directImageUrl.isNotEmpty ? dispatchData.directImageUrl : anchorImageUrl.value);
            } else if (status.toLowerCase() == 'failed' || status.toLowerCase() == 'error') {
              _onGenerationFailed('Generation task failed on backend. 1.0 credit refunded.');
            }
          },
        );
      }
    } else {
      isGenerating.value = false;
      generationProgress.value = 0;
      generationPhase.value = '';
      final msg = result.failure?.message ??
          'Could not dispatch image remix. Please check your connection and tap retry.';
      _showUserError(RemixServerFailure(msg));
    }
  }

  void _onGenerationFailed(String errorMessage) {
    _progressSub?.cancel();
    final shellCtrl = Get.isRegistered<ShellController>() ? Get.find<ShellController>() : null;
    shellCtrl?.addCredits(1.0); // Refund optimistically deducted credit
    if (isClosed) return;
    isGenerating.value = false;
    generationProgress.value = 0;
    generationPhase.value = '';
    _showUserError(RemixServerFailure(errorMessage));
  }

  void _onGenerationCompleted(String imageUrl) {
    _progressSub?.cancel();
    // Save to Cloud Library regardless of screen closure so generated artwork is never lost
    if (Get.isRegistered<LibraryController>()) {
      Get.find<LibraryController>().addNewCreation(
        prompt: currentCompiledPrompt.value,
        credits: 1.0,
        previewUrl: imageUrl,
      );
    }

    if (isClosed) return;

    generationProgress.value = 100;
    generationPhase.value = 'Synthesis completed!';
    lastGeneratedImageUrl.value = imageUrl;
    isGenerating.value = false;

    // Add generated image message bubble to chat stream
    messages.add(
      RemixMessageModel(
        id: 'msg_gen_${DateTime.now().millisecondsSinceEpoch}',
        sessionId: session.value?.id ?? 'sess_active',
        role: 'assistant',
        content: '✨ New Remix Variation Generated! Compare with anchor below:',
        generatedImageUrl: imageUrl,
        createdAt: DateTime.now(),
      ),
    );

    HapticFeedback.heavyImpact();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (isClosed) return;
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showUserError(RemixFailure failure) {
    AppLogger.w('Remix user notice: [${failure.actionLabel}] ${failure.message}', tag: 'REMIX_CHAT');
    if (Get.overlayContext != null || Get.key.currentState?.overlay != null) {
      Get.snackbar(
        failure.actionLabel ?? 'Notice',
        failure.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: failure is RemixInsufficientCreditsFailure
            ? AppColors.orangeAccent
            : AppColors.primary,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
      );
    }
  }

  @override
  void onClose() {
    _progressSub?.cancel();
    inputController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}
