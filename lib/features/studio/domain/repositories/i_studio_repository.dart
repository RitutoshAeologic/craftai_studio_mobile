import 'dart:async';
import '../failures/studio_failure.dart';
import '../models/prompt_expand_model.dart';
import '../models/prompt_compile_model.dart';
import '../models/generation_dispatch_model.dart';
import '../../../remix/domain/models/remix_session_model.dart';
import '../../../remix/domain/models/remix_chat_turn_result.dart';

typedef StudioResult<T> = ({T? data, StudioFailure? failure});

abstract class IStudioRepository {
  /// 1-Shot prompt expansion (Studio Step 1)
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'groq',
  });

  /// Delta Instruction Compiler (Chat Copilot Step 3A)
  Future<StudioResult<PromptCompileModel>> compileChatDelta({
    required String basePrompt,
    required String userInstruction,
    int turnCount = 1,
    String aiEngine = 'groq',
  });

  /// Zero-token 1-click tool presets
  Future<StudioResult<String>> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
    String? imageUrl,
  });

  /// Real zero-token local CPU background removal (outputs transparent PNG URL)
  Future<StudioResult<String>> removeBackground({required String imageUrl});

  /// Automated Tier 0/Tier 1 Generation Dispatcher
  Future<StudioResult<GenerationDispatchModel>> dispatchGeneration({
    required String prompt,
    String? characterId,
    List<String>? faceReferenceUrls,
    String? negativePrompt,
    int? seed,
    Map<String, dynamic>? structuredMetadata,
    int width = 1024,
    int height = 1024,
    String? model,
    String? remixedFromPromptId,
  });

  /// Progress listener with automatic HTTP recovery
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  });

  /// Creates a dedicated Remix Chat Session
  Future<StudioResult<RemixSessionModel>> createRemixSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
    double styleWeight = 0.60,
  }) async => (data: null, failure: null);

  /// Fetches an existing Remix Chat Session
  Future<StudioResult<RemixSessionModel>> getRemixSession({
    required String sessionId,
  }) async => (data: null, failure: null);

  /// Executes a conversational remix delta turn
  Future<StudioResult<RemixChatTurnResult>> sendRemixChatMessage({
    required String sessionId,
    required String userInstruction,
    String aiModel = 'groq',
    double? styleWeight,
  }) async => (data: null, failure: null);

  /// Skill 2: AI Backgrounds
  Future<StudioResult<String>> generateAiBackground({
    required String imageUrl,
    String mode = 'pure_white',
    String? customBackdrop,
    String aspectRatio = 'Auto',
    String quality = '1k',
    String? userId,
  }) async => (data: null, failure: null);

  /// Skill 3: AI Expand
  Future<StudioResult<String>> executeAiExpand({
    required String imageUrl,
    String targetRatio = '16:9',
    String quality = '1k',
    String? userId,
  }) async => (data: null, failure: null);

  /// Skill 4: Upscale 4K
  Future<StudioResult<String>> upscaleImage({
    required String imageUrl,
    int scaleFactor = 2,
    String? userId,
  }) async => (data: null, failure: null);

  /// Skill 5: Product Detail Images
  Future<StudioResult<String>> executeProductDetail({
    String? imageUrl,
    String productName = 'Commercial Product',
    String aspectRatio = '4:5',
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async => (data: null, failure: null);

  /// Skill 6: Marketing Poster
  Future<StudioResult<String>> generateMarketingPoster({
    required String topic,
    String? imageUrl,
    String category = 'Promotion',
    String aspectRatio = '4:5',
    String? headline,
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async => (data: null, failure: null);

  /// Skill 7: Magic Object Eraser (Zero-Hallucination LaMa Inpainting)
  Future<StudioResult<String>> eraseObject({
    required String imageUrl,
    required String maskBase64,
    String? imageBase64,
  }) async => (data: null, failure: null);

  /// Skill 8: Vintage Photo Colorizer (DDColor High-Fidelity Restorer)
  Future<StudioResult<String>> colorizePhoto({
    required String imageUrl,
    double saturation = 1.2,
    String? imageBase64,
  }) async => (data: null, failure: null);

  /// Multimodal Aesthetic Vision Scanner
  Future<StudioResult<Map<String, dynamic>>> scanVisionImage({
    required String imageUrl,
  }) async => (data: null, failure: null);

  /// Ephemeral face-lock reference cleanup
  Future<void> cleanupReferencePhoto(String imageUrl) async {}

  /// Dynamic Multi-LLM runtime configuration
  Future<StudioResult<Map<String, dynamic>>> fetchLlmConfig() async => (data: null, failure: null);

  /// System health verification
  Future<bool> checkSystemHealth() async => false;
}
