import 'dart:async';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_compile_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/remix/domain/models/remix_session_model.dart';
import 'package:craftai_studio_mobile/features/remix/domain/models/remix_chat_turn_result.dart';

export 'package:craftai_studio_mobile/features/remix/domain/models/remix_session_model.dart';
export 'package:craftai_studio_mobile/features/remix/domain/models/remix_chat_turn_result.dart';

class FakeStudioRepository implements IStudioRepository {
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
    String? imageUrl,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<String>> removeBackground({required String imageUrl}) async => (data: null, failure: null);

  @override
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
  }) async => (data: null, failure: null);

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
    void Function(String outputUrl)? onCompleted,
  }) => null;

  @override
  Future<StudioResult<RemixSessionModel>> createRemixSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
    double styleWeight = 0.60,
  }) async => (data: null, failure: null);

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
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<String>> generateAiBackground({
    required String imageUrl,
    String mode = 'pure_white',
    String? customBackdrop,
    String aspectRatio = 'Auto',
    String quality = '1k',
    bool harmonizeLighting = true,
    String? userId,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<String>> executeAiExpand({
    required String imageUrl,
    String targetRatio = '16:9',
    String quality = '1k',
    String? userId,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<String>> upscaleImage({
    required String imageUrl,
    int scaleFactor = 2,
    String? userId,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<String>> executeProductDetail({
    String? imageUrl,
    String productName = 'Commercial Product',
    String aspectRatio = '4:5',
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<String>> generateMarketingPoster({
    required String topic,
    String? imageUrl,
    String category = 'Promotion',
    String aspectRatio = '4:5',
    String? headline,
    String? subtext,
    String? discountBadge,
    String? theme,
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async => (data: null, failure: null);

  @override
  Future<StudioResult<Map<String, dynamic>>> executeProductPack({
    String? imageUrl,
    String productName = 'Commercial Product',
    String? userId,
  }) async => (
        data: {
          'pack': {
            'amazon_white': 'https://images.unsplash.com/mock-amazon.png',
            'studio_pedestal': 'https://images.unsplash.com/mock-pedestal.png',
            'lifestyle_table': 'https://images.unsplash.com/mock-lifestyle.png',
            'story_flyer': 'https://images.unsplash.com/mock-story.png',
          },
          'all_urls': [
            'https://images.unsplash.com/mock-amazon.png',
            'https://images.unsplash.com/mock-pedestal.png',
            'https://images.unsplash.com/mock-lifestyle.png',
            'https://images.unsplash.com/mock-story.png',
          ],
          'product_name': productName,
        },
        failure: null,
      );

  @override
  Future<StudioResult<String>> eraseObject({
    required String imageUrl,
    required String maskBase64,
    String? imageBase64,
  }) async => (data: 'https://images.unsplash.com/mock-erased.png', failure: null);

  @override
  Future<StudioResult<Map<String, dynamic>>> executeMagicGrab({
    required String imageUrl,
    required String maskBase64,
    String? imageBase64,
  }) async => (
        data: {
          'cutout_url': 'https://images.unsplash.com/mock-cutout.png',
          'background_url': 'https://images.unsplash.com/mock-bg-infill.png',
          'all_urls': [
            'https://images.unsplash.com/mock-cutout.png',
            'https://images.unsplash.com/mock-bg-infill.png',
          ],
        },
        failure: null,
      );

  @override
  Future<StudioResult<String>> colorizePhoto({
    required String imageUrl,
    double saturation = 1.2,
    String? imageBase64,
  }) async => (data: 'https://images.unsplash.com/mock-colorized.png', failure: null);

  @override
  Future<StudioResult<Map<String, dynamic>>> scanVisionImage({
    required String imageUrl,
  }) async => (data: {'extracted_prompt': 'A mock visual scene'}, failure: null);

  @override
  Future<void> cleanupReferencePhoto(String imageUrl) async {}

  @override
  Future<StudioResult<Map<String, dynamic>>> fetchLlmConfig() async => (data: <String, dynamic>{}, failure: null);

  @override
  Future<bool> checkSystemHealth() async => true;
}

