import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/shared/utils/reference_image_uploader.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/data/models/character_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import '../../domain/repositories/i_studio_repository.dart';
import '../../domain/failures/studio_failure.dart';
import '../../data/repositories/studio_repository_impl.dart';
import '../views/prompt_chat_copilot_view.dart';
import '../widgets/studio_error_sheet.dart';
import '../widgets/studio_prompt_inspector_sheet.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';

/// [StudioController] is the central brain of the MeiGen creative canvas.
///
/// Core Responsibilities:
/// - Manages user creative state (prompt text, aspect ratio, resolution, model selection)
/// - Handles reference photo selection and zero-retention ephemeral privacy uploads
/// - Connects to LLM prompt expanders ([enhancePrompt] via Gemini, Groq, Claude)
/// - Implements Subject-Lock prompt synthesis for character consistency
/// - Orchestrates generation dispatch, WebSocket progress tracking, and [LibraryController] persistence
class StudioController extends GetxController {
  final IStudioRepository _repository;

  StudioController({IStudioRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<IStudioRepository>()
                ? Get.find<IStudioRepository>()
                : StudioRepositoryImpl());

  /// Text controller managing the prompt input field.
  final TextEditingController promptController = TextEditingController();
  StreamSubscription? _progressSubscription;

  /// Number of images to generate concurrently (default 1).
  final RxInt batchCount = 1.obs;

  /// Whether the diffusion seed should remain locked across successive generations.
  final RxBool isSeedLocked = false.obs;

  /// Target aspect ratio for generation ('1:1', '9:16', '16:9', '4:5', 'Auto').
  final RxString selectedAspectRatio = '1:1'.obs;

  /// Target image resolution tier ('HD', '2K', '4K').
  final RxString selectedResolution = '2K'.obs;

  /// Currently selected diffusion model ('flux', 'gemini', 'chatgpt').
  final RxString selectedModel = 'flux'.obs;

  /// Currently selected LLM for prompt expansion ('gemini', 'groq', 'claude', 'gpt4').
  final RxString selectedPromptEngine = 'gemini'.obs;

  /// Available prompt engineering LLM engines with speed and quality descriptors.
  final List<Map<String, String>> availablePromptEngines = const [
    {
      'id': 'gemini',
      'name': 'Gemini 2.5 Flash',
      'desc': 'Rich visual semantics & optics',
      'icon': '♊',
      'badge': 'Creative',
    },
    {
      'id': 'groq',
      'name': 'Groq LPU (Llama 3.3)',
      'desc': 'Ultra-fast sub-second generation',
      'icon': '⚡',
      'badge': '<0.3s',
    },
    {
      'id': 'claude',
      'name': 'Claude 3.5 Sonnet',
      'desc': 'Photorealistic master prompter',
      'icon': '🧠',
      'badge': 'Photoreal',
    },
    {
      'id': 'gpt4',
      'name': 'GPT-4o Mini',
      'desc': 'Balanced diffusion syntax',
      'icon': '🤖',
      'badge': 'Balanced',
    },
  ];

  /// Updates the active LLM engine used for the "✨ Enhance" Magic Wand feature.
  void setPromptEngine(String id) {
    if (isBusy) return;
    selectedPromptEngine.value = id;
  }

  /// List of local file paths or remote Supabase URLs used as reference photos.
  final RxList<String> referenceImages = <String>[].obs;

  /// Attribution ID if this creation was remixed from a community prompt card.
  final RxnString remixedFromPromptId = RxnString();

  /// Currently locked character consistency profile (if active).
  final Rxn<CharacterModel> selectedCharacter = Rxn<CharacterModel>();

  /// Whether the creative canvas is currently editing an existing image (image-to-image).
  final RxBool isImageEditMode = false.obs;

  /// Remaining free image-to-image edit attempts (starts with 5 free attempts per user specification).
  final RxInt freeEditAttemptsRemaining = 5.obs;

  /// Indicates whether generation is actively in-flight.
  final RxBool isGenerating = false.obs;

  /// Indicates whether prompt enhancement is actively in-flight (prevents double-tap spam).
  final RxBool isEnhancing = false.obs;

  /// Indicates if a zero-token background removal is in-flight.
  final RxBool isRemovingBackground = false.obs;

  /// Unified state indicator: true if ANY heavy processing task is active in Studio.
  /// Used to block conflicting tasks, disable interactive inputs, and prevent race conditions.
  bool get isBusy => isGenerating.value || isEnhancing.value || isRemovingBackground.value;

  /// Real-time progress percentage (0 - 100) streamed from backend worker.
  final RxInt generationProgress = 0.obs;

  /// Descriptive human-readable generation phase message (e.g. "Queued in worker").
  final RxString generationPhase = ''.obs;

  /// Live character count of the active prompt text.
  final RxInt promptLength = 0.obs;

  /// 1. What user typed (raw draft captured before AI enhancement)
  final RxString userTypedPrompt = ''.obs;

  /// 2. What Gemini refined (AI master prompt + negative prompt tokens)
  final RxString geminiRefinedPrompt = ''.obs;
  final RxString geminiNegativePrompt = ''.obs;
  final RxString geminiModelUsed = ''.obs;

  /// 3. What is sent for image generation (exact diffusion payload)
  final RxString lastDispatchedPrompt = ''.obs;
  final RxString lastDispatchedModel = ''.obs;
  final RxString lastDispatchedDimensions = ''.obs;

  @override
  void onInit() {
    super.onInit();
    promptController.addListener(() {
      promptLength.value = promptController.text.length;
    });
  }

  final List<String> aspectRatios = const ['Auto', '1:1', '9:16', '16:9', '4:5'];
  final List<String> resolutions = const ['HD', '2K', '4K'];

  final List<Map<String, String>> starterTemplates = const [
    {
      'title': 'Cyberpunk Ronin',
      'icon': '⚡',
      'prompt': 'Cyberpunk ronin standing in neon rain, volumetric lighting, reflective wet asphalt, 8k',
    },
    {
      'title': 'Cinematic Portrait',
      'icon': '📸',
      'prompt': 'Editorial studio portrait, 85mm f/1.4 lens, Rembrandt lighting, photorealistic textures',
    },
    {
      'title': 'Anime Dreamscape',
      'icon': '🌸',
      'prompt': 'Makoto Shinkai aesthetic, golden hour clouds, floating islands, anime scenery, masterpiece',
    },
    {
      'title': '3D Isometric',
      'icon': '🎮',
      'prompt': 'Cute 3D isometric cyberpunk gaming room, clay render, octane lighting, blender 3d',
    },
  ];

  final List<Map<String, String>> availableModels = const [
    {
      'id': 'flux',
      'name': 'FLUX.1 Pro',
      'desc': 'Default • Best for Photorealism & Faces',
      'badge': 'Photoreal',
      'credits': '2 Cr',
      'icon': '⚡',
    },
    {
      'id': 'gemini',
      'name': 'Google Gemini',
      'desc': 'Creative lighting, artistic compositions',
      'badge': 'Creative',
      'credits': '3 Cr',
      'icon': '🎨',
    },
    {
      'id': 'chatgpt',
      'name': 'ChatGPT (OpenAI)',
      'desc': 'High prompt accuracy & complex scenes',
      'badge': 'Accuracy',
      'credits': '3 Cr',
      'icon': '🤖',
    },
  ];

  /// Calculates the total credit cost based on the active diffusion model,
  /// selected resolution (e.g. 4K surcharge), and batch count multiplier.
  /// If in Image Edit Mode and the user has free attempts remaining, cost is 0 Credits (Free Attempt).
  int get calculatedCreditCost {
    if (isImageEditMode.value && freeEditAttemptsRemaining.value > 0) {
      return 0;
    }
    int base = 2;
    if (selectedModel.value == 'gemini') base = 3;
    if (selectedModel.value == 'chatgpt') base = 3;
    if (selectedResolution.value == '4K') base += 2;
    return base * batchCount.value;
  }

  /// Sets the active diffusion model id ('flux', 'gemini', 'chatgpt').
  void setModel(String modelId) {
    if (isBusy) return;
    selectedModel.value = modelId;
  }

  /// Populates the prompt field with a curated starter template prompt.
  void selectStarterTemplate(Map<String, String> template) {
    if (isBusy) {
      Get.snackbar(
        'Studio is Busy ⏳',
        'Please wait for the current task to finish before loading a template.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    promptController.text = template['prompt'] ?? '';
    Get.snackbar(
      '${template['icon']} ${template['title']} ${AppStrings.templateLoadedSuffix}',
      AppStrings.templateAppliedMsg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      duration: const Duration(seconds: 2),
    );
  }

  /// Opens the conversational AI prompt refinement copilot modal sheet.
  void openPromptChatCopilot({String? imageUrl}) {
    if (isGenerating.value) {
      Get.snackbar(
        'Generation in Progress ⏳',
        'Copilot will be available right after image generation completes.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    Get.to(
      () => const PromptChatCopilotView(),
      arguments: {
        'prompt': promptController.text,
        'imageUrl': imageUrl ?? '',
        'aiEngine': selectedPromptEngine.value,
      },
      transition: Transition.downToUp,
    );
  }

  /// Updates the number of images to generate concurrently.
  void setBatchCount(int count) {
    if (isBusy) return;
    batchCount.value = count;
  }

  /// Toggles seed locking for deterministic repeat generations.
  void toggleSeedLock() {
    if (isBusy) return;
    isSeedLocked.value = !isSeedLocked.value;
  }

  /// Updates target aspect ratio ('1:1', '9:16', '16:9', etc.).
  void setAspectRatio(String ratio) {
    if (isBusy) return;
    selectedAspectRatio.value = ratio;
  }

  /// Updates target resolution tier ('HD', '2K', '4K').
  void setResolution(String res) {
    if (isBusy) return;
    selectedResolution.value = res;
  }

  /// Adds a local selfie file to the reference photo list.
  ///
  /// Zero-Retention Privacy Note:
  /// The photo remains strictly on the device at 0ms latency.
  /// It is NOT uploaded until the user explicitly hits "Generate".
  void addReferencePhotoFile(File file) {
    if (isBusy) return;
    if (referenceImages.length < 3) {
      referenceImages.add(file.path);
      Get.snackbar(
        AppStrings.referenceAdded,
        'Photo selected. Ready for generation.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.white,
      );
    }
  }

  /// Adds a remote reference image URL (e.g. from Explore card or web).
  void addReferenceImage(String url) {
    if (isBusy) return;
    if (referenceImages.length < 3) {
      referenceImages.add(url);
      Get.snackbar(
        AppStrings.referenceAdded,
        AppStrings.referenceAddedMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.white,
      );
    }
  }

  /// Explicitly uploads a local reference file to Supabase storage.
  Future<void> uploadReferencePhoto(File file) async {
    if (isBusy) return;
    AppLogger.i('Uploading reference photo: ${file.path}', tag: 'STUDIO_UPLOAD');
    final result = await ReferenceImageUploader.uploadReferenceImage(file);
    if (result.url != null) {
      AppLogger.s('Reference photo uploaded successfully: ${result.url}', tag: 'STUDIO_UPLOAD');
      addReferenceImage(result.url!);
    } else if (result.failure != null) {
      AppLogger.e('Reference photo upload failed: ${result.failure!.message}', tag: 'STUDIO_UPLOAD');
      Get.snackbar(
        'Upload Notice',
        result.failure!.message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
    }
  }

  /// Removes a reference photo at the specified index from the active set.
  void removeReferenceImage(int index) {
    if (isBusy) return;
    if (index >= 0 && index < referenceImages.length) {
      referenceImages.removeAt(index);
    }
  }


  /// Removes background of a reference photo at [index] using zero-token local CPU rembg.
  Future<void> removeBackgroundFromReference(int index) async {
    if (isBusy) return;
    if (index < 0 || index >= referenceImages.length) return;
    final target = referenceImages[index];

    isRemovingBackground.value = true;
    try {
      String remoteUrl = target;
      if (!target.startsWith('http')) {
        Get.snackbar(
          'Processing Photo',
          'Preparing reference image for background removal...',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          duration: const Duration(seconds: 2),
        );
        final upRes = await ReferenceImageUploader.uploadReferenceImage(File(target));
        if (upRes.url == null) {
          throw Exception(upRes.failure?.message ?? 'Failed to upload photo');
        }
        remoteUrl = upRes.url!;
      }

      Get.snackbar(
        '✂️ Removing Background',
        'Extracting clean transparent cutout (Zero-Token)...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 2),
      );

      final result = await _repository.removeBackground(imageUrl: remoteUrl);
      if (result.data != null && result.data!.isNotEmpty) {
        referenceImages[index] = result.data!;
        Get.snackbar(
          '✂️ Background Removed!',
          'Transparent PNG cutout ready and applied to reference.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.accentSuccess,
          duration: const Duration(seconds: 3),
        );
      } else {
        throw Exception(result.failure?.message ?? 'Background removal failed');
      }
    } catch (e) {
      AppLogger.e('Error removing background from reference', tag: 'STUDIO_TOOL', error: e);
      Get.snackbar(
        'Background Removal Notice',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
    } finally {
      isRemovingBackground.value = false;
    }
  }

  /// "✨ Enhance" Magic Wand action:
  /// Dispatches the current user prompt to backend `/expand` using the
  /// selected AI engine (Groq Llama 3.3, Google Gemini, Claude, or GPT-4o).
  /// Enriches the prompt with 85mm lens, Rembrandt lighting, and 8K photoreal details.
  Future<void> enhancePrompt() async {
    if (isBusy) {
      AppLogger.w('Enhance prompt blocked: Studio is currently busy', tag: 'STUDIO_PROMPT');
      return;
    }
    isEnhancing.value = true;

    try {
      final current = promptController.text.trim();
      userTypedPrompt.value = current; // Capture what user typed (Stage 1)

      String promptToSendToAi = current.isEmpty ? 'Cyberpunk visual masterpiece' : current;
      String? editPrefix;

      // Option A for Image Edit Mode:
      // Recognize that image1 is being edited, preserve 'Edit image1 as follows: ',
      // and expand the user's modifications into rich diffusion descriptors (lighting, texture, lens specs).
      final lower = current.toLowerCase();
      if (lower.startsWith('edit image1 as follows:')) {
        editPrefix = current.substring(0, 'edit image1 as follows:'.length);
        final userEdits = current.substring(editPrefix.length).trim();
        promptToSendToAi = userEdits.isNotEmpty
            ? userEdits
            : 'enhance visual details, cinematic lighting, 85mm lens, photorealistic textures, 8k resolution';
      }

      AppLogger.i('Enhancing prompt via engine "${selectedPromptEngine.value}" | AI Query: "$promptToSendToAi"', tag: 'STUDIO_PROMPT');
      final result = await _repository.expandPrompt(
        promptToSendToAi,
        aspectRatio: selectedAspectRatio.value,
        aiEngine: selectedPromptEngine.value,
      );

      if (result.data != null) {
        if (editPrefix != null) {
          geminiRefinedPrompt.value = '$editPrefix ${result.data!.masterPrompt}';
        } else {
          geminiRefinedPrompt.value = result.data!.masterPrompt;
        }
        geminiNegativePrompt.value = result.data!.negativePrompt;
        geminiModelUsed.value = result.data!.modelUsed;

        // Option A: Clean UI Prompt Preservation
        // We preserve the user's clean prompt in the input field (do not overwrite with 700-char formula).
        // The master formula is armed in background for engine dispatch.
        AppLogger.s('Prompt enhanced successfully via ${result.data!.modelUsed}', tag: 'STUDIO_PROMPT');

        // Formatted 4-Stage Lifecycle Audit Log
        AppLogger.logPromptLifecycle(
          userTyped: userTypedPrompt.value,
          geminiRefined: geminiRefinedPrompt.value,
          negativePrompt: geminiNegativePrompt.value,
          userSees: promptController.text,
          engine: geminiModelUsed.value,
        );

        if (!Platform.environment.containsKey('FLUTTER_TEST')) {
          Get.snackbar(
            AppStrings.magicPromptEnhanced,
            'AI Master Formula Armed! (${result.data!.modelUsed})',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.surface,
            colorText: AppColors.primary,
          );
        }
      } else if (result.failure != null) {
        AppLogger.e('Prompt enhancement failed: ${result.failure!.message}', tag: 'STUDIO_PROMPT');
        if (!Platform.environment.containsKey('FLUTTER_TEST')) {
          Get.snackbar(
            'Enhancement Notice',
            result.failure!.message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: AppColors.surface,
            colorText: AppColors.accentWarning,
          );
        }
      }
    } catch (e, st) {
      AppLogger.e('Unexpected error in enhancePrompt', tag: 'STUDIO_PROMPT', error: e, stackTrace: st);
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        Get.snackbar(
          'Enhancement Notice',
          'Could not enhance prompt right now. Your current text is preserved.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.accentWarning,
        );
      }
    } finally {
      isEnhancing.value = false;
    }
  }

  /// Copies the active prompt directly to the clipboard so the user can test
  /// or execute it across external AI tools (Gemini Web, Midjourney, ChatGPT).
  void copyPromptToClipboard() {
    final text = promptController.text.trim();
    if (text.isEmpty) {
      Get.snackbar(
        'Prompt is Empty',
        'Write or enhance a prompt first before copying.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Prompt Copied! 📋',
      'Refined prompt copied to clipboard! Ready to paste into Gemini, Midjourney, or Flux.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      duration: const Duration(seconds: 3),
    );
  }

  /// Restores the raw prompt originally typed by the user before AI enhancement
  void restoreUserTypedPrompt() {
    if (isBusy) return;
    if (userTypedPrompt.value.isNotEmpty) {
      promptController.text = userTypedPrompt.value;
      Get.snackbar(
        'Draft Restored ↩️',
        'Reverted back to your original unenhanced text draft.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
      );
    }
  }

  /// Whether Gemini prompt refinement is armed for the next generation
  bool get isPromptEnhanced => geminiRefinedPrompt.value.isNotEmpty;

  /// Disarms the Gemini enhancement so the user can generate using raw text
  void clearEnhancement() {
    if (isBusy) return;
    geminiRefinedPrompt.value = '';
    geminiNegativePrompt.value = '';
    geminiModelUsed.value = '';
    Get.snackbar(
      'AI Formula Disarmed ↩️',
      'Generation will use your exact raw prompt text.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textSecondary,
      duration: const Duration(seconds: 2),
    );
  }

  /// Opens the 4-stage Prompt Lifecycle Inspector sheet
  void openPromptInspectorSheet(BuildContext context) {
    StudioPromptInspectorSheet.show(context, this);
  }

  /// Prepends strict Subject-Lock instructions to the prompt to preserve identity.
  void aiEditSubjectLock() {
    if (isBusy) return;
    final current = promptController.text.trim();
    promptController.text =
        'DO NOT CHANGE THE HUMAN SUBJECT. HUMAN SUBJECT — ABSOLUTE LOCK. $current';
    Get.snackbar(
      'Subject Lock Activated',
      'Subject preservation constraints prepended to prompt.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.purpleAccent,
    );
  }

  /// Populates the prompt and provenance ID from an Explore community card remix.
  void loadPromptFromRemix(ExploreCardModel card) {
    if (isBusy) return;
    remixedFromPromptId.value = card.id;
    promptController.text = card.maskedSummary.replaceAll(' • [Secret Recipe Encrypted]', '');
    Get.snackbar(
      AppStrings.remixLoaded,
      'Created by ${card.authorName} (${(card.creatorRoyaltyCut / card.remixFee * 100).toInt()}% royalty to author)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
    );
  }

  /// "⚡ Remix on My Photo" flow:
  /// 1. Saves [card.id] to [remixedFromPromptId] for creator royalty attribution
  /// 2. Sets [userPhoto] as the reference photo
  /// 3. Injects Subject-Lock constraints combined with the card's artistic style
  void remixOnMyPhoto(ExploreCardModel card, File userPhoto) {
    if (isBusy) return;
    remixedFromPromptId.value = card.id;
    referenceImages.clear();
    referenceImages.add(userPhoto.path);
    final cleanPrompt = card.maskedSummary.replaceAll(' • [Secret Recipe Encrypted]', '');
    promptController.text =
        'DO NOT CHANGE THE HUMAN SUBJECT. HUMAN SUBJECT — ABSOLUTE LOCK. $cleanPrompt';
    Get.snackbar(
      'Style Remix Activated',
      'Original style by ${card.authorName} applied to your photo with Subject Lock!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
    );
  }

  /// "✨ Describe Edits" Flow (MeiGen Parity):
  /// 1. Attaches the image as `image1` in the reference strip
  /// 2. Pre-fills the prompt with `'Edit image1 as follows: '`
  /// 3. Positions cursor at the end ready for typing
  /// 4. Sets [isImageEditMode] to true and applies free edit discount if attempts remain
  void loadForImageEdit({required String imageUrl, String? initialPrompt}) {
    if (isBusy) return;
    referenceImages.assignAll([imageUrl]);
    isImageEditMode.value = true;
    final prefix = 'Edit image1 as follows: ';
    promptController.text = prefix;
    promptController.selection = TextSelection.fromPosition(
      TextPosition(offset: promptController.text.length),
    );
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      Get.snackbar(
        'Image Edit Mode Active ✏️',
        freeEditAttemptsRemaining.value > 0
            ? 'Describe changes to image1. Free edit attempt active (${freeEditAttemptsRemaining.value} left)!'
            : 'Describe your changes to image1.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// "🔄 Use Prompt" Flow: Loads raw prompt directly into Studio without image reference
  void loadPromptText(String prompt) {
    if (isBusy) return;
    promptController.text = prompt;
    isImageEditMode.value = false;
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      Get.snackbar(
        'Prompt Loaded 🔄',
        'Prompt ready in Studio canvas.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 2),
      );
    }
  }

  /// Primary Visual Image Generation flow:
  /// 1. Verifies sufficient user wallet credits
  /// 2. Blocks conflicting concurrent operations
  /// 3. Optimistically deducts credits via [ShellController]
  /// 4. Dispatches generation job to FastAPI `/generation/dispatch`
  /// 5. Automatically purges references on backend post-generation
  /// 6. Saves finished creation to [LibraryController]
  /// 7. Automatically resets all loading states on success or error
  Future<void> generateVisual() async {
    if (isBusy) {
      AppLogger.w('Generation dispatch blocked: Studio is currently busy', tag: 'STUDIO_GEN');
      return;
    }

    final shellCtrl = Get.find<ShellController>();
    final cost = calculatedCreditCost.toDouble();
    if (shellCtrl.userCredits.value < cost) {
      Get.snackbar(
        AppStrings.insufficientCredits,
        AppStrings.insufficientCreditsMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
      return;
    }

    final promptUsed = promptController.text.trim();
    if (promptUsed.isEmpty) {
      Get.snackbar(
        AppStrings.promptRequired,
        AppStrings.promptEmptyError,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
      return;
    }

    if (userTypedPrompt.value.isEmpty) {
      userTypedPrompt.value = promptUsed;
    }

    // Option A: If enhanced, dispatch the secret master recipe to the engine!
    final rawPrompt = isPromptEnhanced ? geminiRefinedPrompt.value : promptUsed;
    final promptToDispatch = rawPrompt.length > 4000 ? rawPrompt.substring(0, 4000) : rawPrompt;

    lastDispatchedPrompt.value = promptToDispatch; // Stage 3: sent for generation
    lastDispatchedModel.value = selectedModel.value;
    final w = selectedAspectRatio.value == '9:16' ? 768 : 1024;
    final h = selectedAspectRatio.value == '9:16' ? 1344 : 1024;
    lastDispatchedDimensions.value = '${w}x$h (${selectedAspectRatio.value})';

    // Formatted 4-Stage Lifecycle Audit Log
    AppLogger.logPromptLifecycle(
      userTyped: userTypedPrompt.value,
      geminiRefined: geminiRefinedPrompt.value,
      negativePrompt: geminiNegativePrompt.value,
      sentForGeneration: lastDispatchedPrompt.value,
      userSees: promptController.text,
      model: selectedModel.value,
      engine: geminiModelUsed.value,
    );

    AppLogger.i('🚀 Dispatching Visual Generation | Model: ${selectedModel.value} | Aspect: ${selectedAspectRatio.value} | Cost: $cost Cr | Prompt: "$promptToDispatch"', tag: 'STUDIO_GEN');
    
    // Set initial loading state
    isGenerating.value = true;
    generationProgress.value = 8;
    generationPhase.value = 'Preparing creative canvas...';

    bool creditsDeducted = false;
    shellCtrl.deductCredits(cost);
    creditsDeducted = true;

    try {
      // 1. Lazy upload any local reference files first, reflecting upload state in UI
      final List<String> remoteReferenceUrls = [];
      if (referenceImages.isNotEmpty) {
        generationProgress.value = 18;
        generationPhase.value = 'Uploading reference photo...';
      } else {
        generationProgress.value = 12;
        generationPhase.value = AppStrings.queuedInWorker;
      }

      for (final ref in referenceImages) {
        if (ref.startsWith('http://') || ref.startsWith('https://')) {
          remoteReferenceUrls.add(ref);
        } else {
          AppLogger.i('Uploading confirmed reference photo before generation: $ref', tag: 'STUDIO_UPLOAD');
          final upRes = await ReferenceImageUploader.uploadReferenceImage(File(ref));
          if (upRes.url != null) {
            remoteReferenceUrls.add(upRes.url!);
          }
        }
      }

      // 2. Start progress subscription and dispatch generation
      final taskId = 'task_${DateTime.now().millisecondsSinceEpoch}';

      _progressSubscription?.cancel();
      _progressSubscription = _repository.listenToGenerationProgress(
        taskId: taskId,
        onProgress: (progress, status, message) {
          if (isGenerating.value) {
            generationProgress.value = progress;
            generationPhase.value = message.isNotEmpty ? message : 'Denoising latents...';
            AppLogger.d('[$taskId] Progress: $progress% ($message)', tag: 'STUDIO_GEN');
          }
        },
      );

      final dispatchRes = await _repository.dispatchGeneration(
        prompt: promptToDispatch,
        characterId: selectedCharacter.value?.id,
        faceReferenceUrls: remoteReferenceUrls.isNotEmpty ? remoteReferenceUrls : null,
        width: selectedAspectRatio.value == '9:16' ? 768 : 1024,
        height: selectedAspectRatio.value == '9:16' ? 1344 : 1024,
        model: selectedModel.value,
        remixedFromPromptId: remixedFromPromptId.value,
      );

      // 3. Robust Error Handling (Rules.md §2 & §6):
      if (dispatchRes.failure != null || dispatchRes.data == null) {
        _progressSubscription?.cancel();
        _resetLoadingState();
        if (creditsDeducted) {
          shellCtrl.addCredits(cost); // Refund optimistically deducted credits
          creditsDeducted = false;
        }

        final failure = dispatchRes.failure ?? const StudioUnknownFailure('Generation failed. Credits refunded.');
        AppLogger.w('Generation dispatch failed: ${failure.message}', tag: 'STUDIO_GEN');

        StudioErrorSheet.show(
          failure: failure,
          refundedCredits: cost,
          onRetry: () => generateVisual(),
        );
        return;
      }

      final rawUrl = dispatchRes.data?.directImageUrl;
      if (rawUrl == null || rawUrl.trim().isEmpty || !rawUrl.startsWith('http')) {
        _progressSubscription?.cancel();
        _resetLoadingState();
        if (creditsDeducted) {
          shellCtrl.addCredits(cost); // Refund optimistically deducted credits
          creditsDeducted = false;
        }

        StudioErrorSheet.show(
          failure: const StudioServerFailure('Server did not return a valid rendered image URL. Credits refunded.'),
          refundedCredits: cost,
          onRetry: () => generateVisual(),
        );
        return;
      }

      final outputUrl = rawUrl;
      final generatedTaskId = dispatchRes.data?.taskId ?? 'job_${DateTime.now().millisecondsSinceEpoch}';

      final libCtrl = Get.find<LibraryController>();
      libCtrl.addNewCreation(
        prompt: promptUsed,
        credits: cost,
        previewUrl: outputUrl,
      );

      // Persist to Supabase jobs table (use upsert to handle jobs created by backend)
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          await SupabaseService.client.from('jobs').upsert({
            'job_id': generatedTaskId,
            'user_id': user.id,
            'type': 'IMAGE_GEN',
            'status': 'completed',
            'prompt': promptUsed,
            'preview_url': outputUrl,
            'credits_deducted': cost,
            'is_download_unlocked': false,
          }, onConflict: 'job_id');
          AppLogger.s('Saved generation $generatedTaskId to Supabase jobs table', tag: 'STUDIO_GEN');
        }
      } catch (e) {
        AppLogger.d('Cloud job save skipped or table not yet created: $e', tag: 'STUDIO_GEN');
      }

      AppLogger.s('✨ Generation complete! Saved to Library. Output URL: $outputUrl', tag: 'STUDIO_GEN');

      // Consume one free edit attempt if generated in image edit mode
      if (isImageEditMode.value && freeEditAttemptsRemaining.value > 0) {
        freeEditAttemptsRemaining.value--;
        AppLogger.i('Free edit attempt consumed. Remaining: ${freeEditAttemptsRemaining.value}', tag: 'STUDIO_GEN');
      }

      // 4. Smooth Loading Completion and Reset After Success
      _progressSubscription?.cancel();
      generationProgress.value = 100;
      generationPhase.value = '✨ Complete! Opening Library...';
      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        await Future.delayed(const Duration(milliseconds: 400));
      }

      // Reset loading progress cleanly so canvas is fresh when user returns
      _resetLoadingState();

      if (!Platform.environment.containsKey('FLUTTER_TEST')) {
        Get.snackbar(
          AppStrings.generationCompleted,
          AppStrings.generationCompletedSub,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.primary,
          duration: const Duration(seconds: 4),
          mainButton: TextButton(
            onPressed: () => openPromptChatCopilot(),
            child: Text(
              AppStrings.btnRefineInChat,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }

      shellCtrl.switchTab(3); // navigate to library
    } catch (e, st) {
      AppLogger.e('Unexpected error in generateVisual', tag: 'STUDIO_GEN', error: e, stackTrace: st);
      _progressSubscription?.cancel();
      _resetLoadingState();

      if (creditsDeducted) {
        shellCtrl.addCredits(cost);
        creditsDeducted = false;
      }

      final failure = _mapExceptionToFriendlyFailure(e);
      StudioErrorSheet.show(
        failure: failure,
        refundedCredits: cost,
        onRetry: () => generateVisual(),
      );
    } finally {
      if (isGenerating.value) {
        _resetLoadingState();
      }
    }
  }

  /// Resets all generation loading states back to initial clean state.
  void _resetLoadingState() {
    isGenerating.value = false;
    generationProgress.value = 0;
    generationPhase.value = '';
  }

  /// Maps unexpected Dart/Dio exceptions to user-friendly StudioFailure objects.
  StudioFailure _mapExceptionToFriendlyFailure(dynamic error) {
    if (error is StudioFailure) return error;
    final str = error.toString().toLowerCase();
    if (str.contains('socketexception') || str.contains('connection refused') || str.contains('network')) {
      return const StudioNetworkFailure('Unable to reach generation server. Please check your connection and retry.');
    }
    if (str.contains('timeout')) {
      return const StudioTimeoutFailure('The generation took too long to complete. Credits refunded, please retry.');
    }
    return StudioUnknownFailure(
      'An unexpected issue occurred while generating. Credits have been refunded: ${error.toString().replaceAll('Exception: ', '')}',
    );
  }

  @override
  void onClose() {
    _progressSubscription?.cancel();
    promptController.dispose();
    super.onClose();
  }
}
