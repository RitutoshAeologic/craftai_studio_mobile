import 'dart:async';
import '../failures/studio_failure.dart';
import '../models/prompt_expand_model.dart';
import '../models/prompt_compile_model.dart';
import '../models/generation_dispatch_model.dart';

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
  });

  /// Real zero-token local CPU background removal (outputs transparent PNG URL)
  Future<StudioResult<String>> removeBackground({required String imageUrl});

  /// Automated Tier 0/Tier 1 Generation Dispatcher
  Future<StudioResult<GenerationDispatchModel>> dispatchGeneration({
    required String prompt,
    String? characterId,
    List<String>? faceReferenceUrls,
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
}
