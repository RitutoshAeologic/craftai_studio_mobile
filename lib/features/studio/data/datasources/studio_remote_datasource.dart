import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/models/prompt_expand_model.dart';
import '../../domain/models/prompt_compile_model.dart';
import '../../domain/models/generation_dispatch_model.dart';
import '../../../remix/domain/models/remix_session_model.dart';
import '../../../../core/network/dio_logging_interceptor.dart';
import '../../../../core/network/connectivity_interceptor.dart';
import '../../../../core/network/api_config.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';

/// [StudioRemoteDataSource] is the network gateway for all Studio generation,
/// prompt enhancement, creative AI skills, and WebSocket streaming operations with FastAPI.
class StudioRemoteDataSource {
  final Dio _dio;

  StudioRemoteDataSource({Dio? dio}) : _dio = dio ?? _createConfiguredDio();

  /// Configures Dio instance with centralized [ApiConfig.baseUrl], auto-injected
  /// Supabase JWT Bearer tokens, and optional remote fallback if explicitly defined.
  static Dio _createConfiguredDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 90),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
          'Bypass-Tunnel-Reminder': 'true',
        },
      ),
    );

    // Fast-fail if device is completely offline before waiting for network timeouts
    dio.interceptors.add(ConnectivityInterceptor());

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          try {
            final token = SupabaseService.client.auth.currentSession?.accessToken;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          } catch (_) {}
          return handler.next(options);
        },
        onError: (err, handler) async {
          if (err.type == DioExceptionType.connectionError ||
              err.type == DioExceptionType.connectionTimeout) {
            final candidateFallbacks = [
              if (ApiConfig.fallbackUrl != null) ApiConfig.fallbackUrl!,
              if (ApiConfig.isAndroidDevice &&
                  (err.requestOptions.baseUrl.contains('127.0.0.1') ||
                      err.requestOptions.baseUrl.contains('localhost')))
                err.requestOptions.baseUrl
                    .replaceAll('127.0.0.1', '10.0.2.2')
                    .replaceAll('localhost', '10.0.2.2'),
              if (ApiConfig.isAndroidDevice &&
                  err.requestOptions.baseUrl.contains('10.0.2.2'))
                err.requestOptions.baseUrl.replaceAll('10.0.2.2', '127.0.0.1'),
            ];

            for (final fallbackUrl in candidateFallbacks) {
              if (err.requestOptions.baseUrl.contains(fallbackUrl)) continue;

              try {
                final fallbackDio = Dio(
                  BaseOptions(
                    baseUrl: fallbackUrl,
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: const Duration(seconds: 40),
                    headers: {
                      'Content-Type': 'application/json',
                      'ngrok-skip-browser-warning': 'true',
                    },
                  ),
                )..interceptors.add(DioLoggingInterceptor());

                final res = await fallbackDio.request(
                  err.requestOptions.path,
                  data: err.requestOptions.data,
                  queryParameters: err.requestOptions.queryParameters,
                  options: Options(
                    method: err.requestOptions.method,
                    headers: err.requestOptions.headers,
                  ),
                );

                return handler.resolve(res);
              } catch (_) {}
            }
          }

          return handler.next(err);
        },
      ),
    );

    dio.interceptors.add(DioLoggingInterceptor());
    return dio;
  }

  /// Sends a raw prompt to the backend LLM expander (`/prompt-engineering/expand`).
  Future<PromptExpandModel> expandPrompt({
    required String rawPrompt,
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'groq',
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/expand',
      data: {
        'raw_prompt': rawPrompt,
        'starter_chip': starterChip,
        'aspect_ratio': aspectRatio,
        'ai_model': aiEngine,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return PromptExpandModel.fromJson(data);
  }

  /// Sends iterative conversational instructions to the prompt copilot (`/prompt-engineering/chat-delta`).
  Future<PromptCompileModel> compileChatDelta({
    required String basePrompt,
    required String userInstruction,
    int turnCount = 1,
    String aiEngine = 'groq',
    String? sessionId,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/chat-delta',
      data: {
        'session_id': sessionId ?? 'sess_${DateTime.now().millisecondsSinceEpoch}',
        'turn_count': turnCount,
        'base_prompt': basePrompt,
        'user_instruction': userInstruction,
        'ai_model': aiEngine,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return PromptCompileModel.fromJson(data);
  }

  /// Applies quick image editing presets (e.g. relight, blur, preset).
  Future<String> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
    String? imageUrl,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/edit-preset',
      data: {
        'image_id': imageId,
        if (imageUrl != null && imageUrl.isNotEmpty) 'image_url': imageUrl,
        'action': action,
        'target_preset': targetPreset,
        'lock_subject': true,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return data['task_id'] as String? ??
        'tool_task_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Real zero-token background removal tool (outputs transparent PNG).
  Future<String?> removeBackground({required String imageUrl}) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/remove-background',
      data: {'image_url': imageUrl},
    );

    final data = response.data as Map<String, dynamic>;
    return data['output_url'] as String? ?? data['image_url'] as String?;
  }

  /// Dispatches an image generation job to `/prompt-engineering/generation/dispatch`.
  /// Follows API_INTEGRATION_SPEC.md §2.1.
  Future<GenerationDispatchModel> dispatchGeneration({
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
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/generation/dispatch',
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
      ),
      data: {
        'prompt': prompt,
        'character_id': characterId,
        'face_reference_urls': faceReferenceUrls,
        if (negativePrompt != null && negativePrompt.trim().isNotEmpty)
          'negative_prompt': negativePrompt.trim(),
        if (seed != null) 'seed': seed,
        if (structuredMetadata != null && structuredMetadata.isNotEmpty)
          'structured_metadata': structuredMetadata,
        'width': width,
        'height': height,
        'model': model ?? 'flux',
        'remixed_from_prompt_id': remixedFromPromptId,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return GenerationDispatchModel.fromJson(data);
  }

  /// Queries the live generation progress status for a specific task.
  /// Follows API_INTEGRATION_SPEC.md §2.2.B.
  Future<Map<String, dynamic>> getGenerationStatus(String taskId) async {
    final response = await _dio.get(
      '/prompt-engineering/status/$taskId',
      options: Options(receiveTimeout: const Duration(seconds: 10)),
    );
    return response.data as Map<String, dynamic>;
  }

  /// Establishes a WebSocket connection to stream real-time generation progress.
  /// Seamlessly falls back to sequential HTTP polling if WebSocket is unavailable.
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) {
    final streamController = StreamController<void>();
    WebSocket? activeSocket;
    Timer? pollTimer;
    bool isCompleted = false;
    bool isPollingActive = false;
    int highestProgress = 0;

    void emitProgress(int progress, String status, String message) {
      if (isCompleted) return;
      highestProgress = progress > highestProgress ? progress : highestProgress;
      onProgress(highestProgress, status, message);
      if (status == 'completed' || status == 'failed') {
        isCompleted = true;
        pollTimer?.cancel();
        activeSocket?.close();
      }
    }

    void startRealPolling() {
      if (isCompleted || pollTimer != null) return;
      int pollCount = 0;
      const maxPolls = 40; // 60s at 1.5s intervals

      pollTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) async {
        if (isCompleted || pollCount++ >= maxPolls) {
          timer.cancel();
          return;
        }
        if (isPollingActive) return; // Prevent concurrent overlapping requests
        isPollingActive = true;

        try {
          final statusData = await getGenerationStatus(taskId);
          final status = statusData['status'] as String? ?? 'processing';
          final progress = statusData['progress'] as int? ?? (pollCount * 3).clamp(15, 90);
          final message = statusData['message'] as String? ?? 'Processing diffusion latents...';

          emitProgress(progress, status, message);
        } catch (_) {
          emitProgress((pollCount * 3).clamp(15, 85), 'processing', 'Denoising latents...');
        } finally {
          isPollingActive = false;
        }
      });
    }

    try {
      final wsUrl = ApiConfig.buildWsGenerationUrl(taskId);
      WebSocket.connect(wsUrl).then((socket) {
        activeSocket = socket;
        socket.listen(
          (event) {
            try {
              final payload = jsonDecode(event.toString()) as Map<String, dynamic>;
              final progress = payload['progress'] as int? ?? 50;
              final status = payload['status'] as String? ?? 'diffusing';
              final message = payload['message'] as String? ?? '';
              emitProgress(progress, status, message);
            } catch (_) {}
          },
          onError: (_) => startRealPolling(),
          onDone: () {
            if (!isCompleted) startRealPolling();
          },
        );
      }).catchError((_) {
        startRealPolling();
      });
    } catch (_) {
      startRealPolling();
    }

    streamController.onCancel = () {
      isCompleted = true;
      pollTimer?.cancel();
      activeSocket?.close();
    };

    return streamController.stream.listen(null);
  }

  /// Dynamic Multi-LLM Runtime Configuration (API_INTEGRATION_SPEC.md §2.3)
  Future<Map<String, dynamic>> fetchLlmConfig() async {
    final response = await _dio.get('/prompt-engineering/config');
    return response.data as Map<String, dynamic>;
  }

  /// System Health Verification (API_INTEGRATION_SPEC.md §2.8)
  Future<bool> checkSystemHealth() async {
    try {
      final response = await _dio.get(
        '/health',
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Ephemeral face-lock reference photo purge (API_INTEGRATION_SPEC.md §2.7)
  Future<void> cleanupReferencePhoto(String imageUrl) async {
    try {
      await _dio.post(
        '/prompt-engineering/cleanup-reference',
        data: {'image_url': imageUrl},
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
    } catch (_) {}
  }

  /// Initializes a dedicated Remix Chat session anchored to a reference image.
  Future<RemixSessionModel> createRemixSession({
    required String anchorImageUrl,
    String sourceType = 'explore',
    String? remixedFromPromptId,
    String? initialPrompt,
    double styleWeight = 0.60,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/remix/sessions',
      data: {
        'anchor_image_url': anchorImageUrl,
        'source_type': sourceType,
        'remixed_from_prompt_id': remixedFromPromptId,
        'initial_prompt': initialPrompt ?? 'Preserve subject with balanced aesthetics',
        'style_weight': styleWeight,
      },
    );

    final data = response.data as Map<String, dynamic>;
    return RemixSessionModel.fromJson(data);
  }

  /// Fetches an existing Remix Chat session with full message turn history.
  Future<RemixSessionModel> getRemixSession({
    required String sessionId,
  }) async {
    final response = await _dio.get(
      '/prompt-engineering/remix/sessions/$sessionId',
    );

    final data = response.data as Map<String, dynamic>;
    return RemixSessionModel.fromJson(data);
  }

  /// Executes a low-latency conversational remix prompt delta turn.
  Future<Map<String, dynamic>> sendRemixChatMessage({
    required String sessionId,
    required String userInstruction,
    String aiModel = 'groq',
    double? styleWeight,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/remix/chat',
      data: {
        'session_id': sessionId,
        'user_instruction': userInstruction,
        'ai_model': aiModel,
        if (styleWeight != null) 'style_weight': styleWeight,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CREATIVE SKILLS TOOLBOX (AI Tools Suite - API_INTEGRATION_SPEC.md §2.5)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Skill 2: Pure white commercial studio canvas or Custom background.
  Future<Map<String, dynamic>> generateAiBackground({
    required String imageUrl,
    String mode = 'pure_white',
    String? customBackdrop,
    String aspectRatio = 'Auto',
    String quality = '1k',
    String? userId,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/ai-background',
      data: {
        'image_url': imageUrl,
        'mode': mode,
        if (customBackdrop != null) 'custom_backdrop': customBackdrop,
        'aspect_ratio': aspectRatio,
        'quality': quality,
        if (userId != null) 'user_id': userId,
      },
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Skill 3: Generative canvas outpaint extension to any aspect ratio.
  Future<Map<String, dynamic>> executeAiExpand({
    required String imageUrl,
    String targetRatio = '16:9',
    String quality = '1k',
    String? userId,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/ai-expand',
      data: {
        'image_url': imageUrl,
        'target_ratio': targetRatio,
        'quality': quality,
        if (userId != null) 'user_id': userId,
      },
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Skill 4: 2X/4K Super-Resolution Detail Restoration.
  Future<Map<String, dynamic>> upscaleImage({
    required String imageUrl,
    int scaleFactor = 2,
    String? userId,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/upscale',
      data: {
        'image_url': imageUrl,
        'scale_factor': scaleFactor,
        if (userId != null) 'user_id': userId,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 60),
        connectTimeout: const Duration(seconds: 60),
      ),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Skill 5: Commercial Product Detail with luxury pedestal staging.
  Future<Map<String, dynamic>> executeProductDetail({
    String? imageUrl,
    String productName = 'Commercial Product',
    String aspectRatio = '4:5',
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/product-detail',
      data: {
        if (imageUrl != null && imageUrl.trim().isNotEmpty) 'image_url': imageUrl,
        'product_name': productName,
        'aspect_ratio': aspectRatio,
        'language': language,
        'quality': quality,
        if (userId != null) 'user_id': userId,
      },
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Skill 6: Commercial Marketing Poster with layout & typography synthesis.
  Future<Map<String, dynamic>> generateMarketingPoster({
    required String topic,
    String? imageUrl,
    String category = 'Promotion',
    String aspectRatio = '4:5',
    String? headline,
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/marketing-poster',
      data: {
        'topic': topic,
        if (imageUrl != null) 'image_url': imageUrl,
        'category': category,
        'aspect_ratio': aspectRatio,
        if (headline != null) 'headline': headline,
        'language': language,
        'quality': quality,
        if (userId != null) 'user_id': userId,
      },
      options: Options(receiveTimeout: const Duration(seconds: 120)),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Skill 7: Magic Object Eraser (Zero-Hallucination LaMa Inpainting - API_INTEGRATION_SPEC.md §2.5.H)
  Future<Map<String, dynamic>> eraseObject({
    required String imageUrl,
    required String maskBase64,
    String? imageBase64,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/remove-object',
      data: {
        'image_url': imageUrl,
        'mask_base64': maskBase64,
        if (imageBase64 != null) 'image_base64': imageBase64,
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Skill 8: Vintage Photo Colorizer (DDColor High-Fidelity Restorer - API_INTEGRATION_SPEC.md §2.5.I)
  Future<Map<String, dynamic>> colorizePhoto({
    required String imageUrl,
    double saturation = 1.2,
    String? imageBase64,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/colorize',
      data: {
        'image_url': imageUrl,
        'saturation': saturation,
        if (imageBase64 != null) 'image_base64': imageBase64,
      },
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Multimodal Aesthetic Vision Scanner (API_INTEGRATION_SPEC.md §2.6)
  Future<Map<String, dynamic>> scanVisionImage(String imageUrl) async {
    final response = await _dio.post(
      '/prompt-engineering/vision-scan',
      data: {'image_url': imageUrl},
      options: Options(receiveTimeout: const Duration(seconds: 45)),
    );

    return response.data as Map<String, dynamic>;
  }
}
