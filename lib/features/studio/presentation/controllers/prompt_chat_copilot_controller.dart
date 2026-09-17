import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import '../../domain/models/copilot_message_model.dart';
import '../../domain/repositories/i_studio_repository.dart';
import '../../data/repositories/studio_repository_impl.dart';
import 'studio_controller.dart';

class PromptChatCopilotController extends GetxController {
  final IStudioRepository _repository;

  PromptChatCopilotController({IStudioRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<IStudioRepository>()
                ? Get.find<IStudioRepository>()
                : StudioRepositoryImpl());

  final TextEditingController inputController = TextEditingController();

  final RxList<CopilotMessage> messages = <CopilotMessage>[].obs;
  final RxString activeBasePrompt = ''.obs;
  final RxString activeImageUrl = ''.obs;
  final RxList<String> activeAddedTags = <String>[].obs;
  final RxList<String> activeRemovedTags = <String>[].obs;
  final RxList<String> suggestionChips = <String>[
    'Add Heavy Rain',
    'Moody Low-Key',
    '35mm Cinematic Lens',
    'Volumetric Smoke',
  ].obs;

  final RxBool isLoading = false.obs;
  final RxInt turnCount = 0.obs;
  final RxString selectedAiEngine = 'groq'.obs;
  late final String sessionId = 'sess_${DateTime.now().millisecondsSinceEpoch}';

  final List<Map<String, String>> quickActionChips = const [
    {'label': AppStrings.chipChangeBackground, 'action': 'change_background', 'preset': 'snowy_mountains', 'icon': 'landscape'},
    {'label': AppStrings.chipChangeTheme, 'action': 'change_theme', 'preset': 'cyberpunk_anime', 'icon': 'palette'},
    {'label': AppStrings.chipStudioLighting, 'action': 'lighting', 'preset': 'dramatic_rim_light', 'icon': 'flash'},
    {'label': AppStrings.chipUpscale4k, 'action': 'upscale', 'preset': 'clarity_4k', 'icon': 'hd'},
  ];

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      activeBasePrompt.value = args['prompt'] ?? '';
      activeImageUrl.value = args['imageUrl'] ?? '';
      selectedAiEngine.value = args['aiEngine'] ?? 'groq';
    } else {
      final studioCtrl = Get.isRegistered<StudioController>() ? Get.find<StudioController>() : null;
      if (studioCtrl != null && studioCtrl.promptController.text.isNotEmpty) {
        activeBasePrompt.value = studioCtrl.promptController.text;
        selectedAiEngine.value = studioCtrl.selectedPromptEngine.value;
      }
    }

    // Welcome greeting
    messages.add(
      CopilotMessage(
        id: 'msg_welcome',
        text: activeBasePrompt.value.isEmpty
            ? AppStrings.copilotWelcomeEmpty
            : AppStrings.copilotWelcomeLoaded,
        isUser: false,
      ),
    );
  }

  void setAiEngine(String engine) {
    selectedAiEngine.value = engine;
  }

  Future<void> sendInstruction(String instruction) async {
    final clean = instruction.trim();
    if (clean.isEmpty || isLoading.value) return;

    if (turnCount.value >= 5) {
      AppLogger.w('Copilot refinement cap reached (5/5 turns)', tag: 'COPILOT');
      Get.snackbar(
        AppStrings.refinementCapReached,
        AppStrings.refinementCapReachedMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.orangeAccent,
      );
      return;
    }

    inputController.clear();
    turnCount.value++;

    AppLogger.i('Sending copilot turn ${turnCount.value}/5 via "${selectedAiEngine.value}": "$clean"', tag: 'COPILOT');

    // Add user message
    messages.add(
      CopilotMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        text: clean,
        isUser: true,
      ),
    );

    isLoading.value = true;

    final base = activeBasePrompt.value.isNotEmpty
        ? activeBasePrompt.value
        : 'Cinematic visual masterpiece';

    final result = await _repository.compileChatDelta(
      basePrompt: base,
      userInstruction: clean,
      turnCount: turnCount.value,
      aiEngine: selectedAiEngine.value,
    );

    if (result.data != null) {
      final compileData = result.data!;
      activeBasePrompt.value = compileData.compiledPrompt;
      activeAddedTags.assignAll(compileData.addedTags);
      activeRemovedTags.assignAll(compileData.removedTags);

      if (compileData.suggestedChips.isNotEmpty) {
        suggestionChips.assignAll(compileData.suggestedChips);
      }

      AppLogger.s('Prompt refined successfully: "${compileData.compiledPrompt}" | Added tags: ${compileData.addedTags}', tag: 'COPILOT');

      messages.add(
        CopilotMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Prompt refined via ${compileData.modelUsed}:\n\n"${compileData.compiledPrompt}"',
          isUser: false,
          addedTags: compileData.addedTags,
          removedTags: compileData.removedTags,
        ),
      );
    } else if (result.failure != null) {
      AppLogger.e('Copilot refinement failed: ${result.failure!.message}', tag: 'COPILOT');
      Get.snackbar(
        'Refinement Error',
        result.failure!.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
    }

    isLoading.value = false;
  }

  Future<void> applyQuickTool(String action, String preset, String label) async {
    if (isLoading.value) return;

    messages.add(
      CopilotMessage(
        id: 'msg_tool_${DateTime.now().millisecondsSinceEpoch}',
        text: 'Action applied: $label ($preset)',
        isUser: true,
      ),
    );

    isLoading.value = true;

    await _repository.applyQuickTool(
      imageId: 'img_active',
      action: action,
      targetPreset: preset,
    );

    if (action == 'change_background') {
      activeBasePrompt.value = '${activeBasePrompt.value}, background replaced with $preset, seamless ambient lighting blend';
      activeAddedTags.add('background: $preset');
    } else if (action == 'change_theme') {
      activeBasePrompt.value = '${activeBasePrompt.value}, in $preset style, vibrant aesthetic';
      activeAddedTags.add('theme: $preset');
    }

    messages.add(
      CopilotMessage(
        id: 'msg_tool_resp_${DateTime.now().millisecondsSinceEpoch}',
        text: '${AppStrings.toolAppliedSuccess}\n\nNew target: "${activeBasePrompt.value}"',
        isUser: false,
        addedTags: [action, preset],
      ),
    );

    isLoading.value = false;
  }

  void syncToStudioAndGenerate() {
    if (Get.isRegistered<StudioController>()) {
      final studioCtrl = Get.find<StudioController>();
      studioCtrl.promptController.text = activeBasePrompt.value;
      Get.back();
      studioCtrl.generateVisual();
    } else {
      Get.back();
    }
  }

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }
}
