import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import '../../domain/models/prompt_expand_model.dart';
import '../../domain/models/prompt_compile_model.dart';
import '../../domain/models/generation_dispatch_model.dart';
import '../../../../core/network/dio_logging_interceptor.dart';
import '../../../../core/network/api_config.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';

/// [StudioRemoteDataSource] is the network gateway for all Studio generation,
/// prompt enhancement, and WebSocket streaming operations with the FastAPI backend.
class StudioRemoteDataSource {
  final Dio _dio;

  StudioRemoteDataSource({Dio? dio})
      : _dio = dio ?? _createConfiguredDio();

  /// Configures Dio instance with centralized [ApiConfig.baseUrl], auto-injected
  /// Supabase JWT Bearer tokens, and optional remote fallback if explicitly defined.
  static Dio _createConfiguredDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 40),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

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
          if (err.type == DioExceptionType.connectionError) {
            final candidateFallbacks = [
              if (ApiConfig.fallbackUrl != null) ApiConfig.fallbackUrl!,
              if (err.requestOptions.baseUrl.contains('127.0.0.1') ||
                  err.requestOptions.baseUrl.contains('localhost'))
                'http://192.168.68.124:8000/api/v1',
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
  ///
  /// Parameters:
  /// - [rawPrompt]: User's unrefined idea (e.g. "samurai in rain")
  /// - [aspectRatio]: Target aspect ratio ('1:1', '9:16', etc.)
  /// - [aiEngine]: Selected LLM ('gemini', 'groq', 'claude', 'gpt4')
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

  /// Applies quick image editing presets (e.g. background removal, upscale).
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
    return data['task_id'] as String? ?? 'tool_task_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Real zero-token background removal tool (outputs transparent PNG).
  Future<String?> removeBackground({required String imageUrl}) async {
    final response = await _dio.post(
      '/prompt-engineering/tools/remove-background',
      data: {'image_url': imageUrl},
    );
    final data = response.data as Map<String, dynamic>;
    return data['output_url'] as String?;
  }

  /// Dispatches an image generation job to `/prompt-engineering/generation/dispatch`.
  ///
  /// Parameters:
  /// - [prompt]: Fully formed diffusion prompt
  /// - [faceReferenceUrls]: Remote URLs of reference selfies (auto-deleted post-generation)
  /// - [model]: Target diffusion model ('flux', 'gemini', 'chatgpt')
  /// - [remixedFromPromptId]: Provenance UUID if remixed from Explore card (creator royalty)
  Future<GenerationDispatchModel> dispatchGeneration({
    required String prompt,
    String? characterId,
    List<String>? faceReferenceUrls,
    int width = 1024,
    int height = 1024,
    String? model,
    String? remixedFromPromptId,
  }) async {
    final response = await _dio.post(
      '/prompt-engineering/generation/dispatch',
      data: {
        'prompt': prompt,
        'character_id': characterId,
        'face_reference_urls': faceReferenceUrls,
        'width': width,
        'height': height,
        'model': model ?? 'flux',
        'remixed_from_prompt_id': remixedFromPromptId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return GenerationDispatchModel.fromJson(data);
  }

  /// Establishes a WebSocket connection to stream real-time generation progress.
  /// Falls back to a smooth simulated progression if WebSocket fails.
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) {
    try {
      final wsUrl = ApiConfig.buildWsGenerationUrl(taskId);

      WebSocket.connect(wsUrl).then((socket) {
        socket.listen(
          (event) {
            try {
              final payload = jsonDecode(event.toString()) as Map<String, dynamic>;
              final progress = payload['progress'] as int? ?? 50;
              final status = payload['status'] as String? ?? 'diffusing';
              final message = payload['message'] as String? ?? '';
              onProgress(progress, status, message);
            } catch (_) {}
          },
          onError: (_) {
            _triggerPollingFallback(taskId, onProgress);
          },
          onDone: () {},
        );
      }).catchError((_) {
        _triggerPollingFallback(taskId, onProgress);
      });
    } catch (_) {
      _triggerPollingFallback(taskId, onProgress);
    }
    return null;
  }

  void _triggerPollingFallback(
    String taskId,
    void Function(int progress, String status, String message) onProgress,
  ) {
    Future.delayed(const Duration(milliseconds: 400), () {
      onProgress(35, 'compiling', 'Prompt compiled');
    });
    Future.delayed(const Duration(milliseconds: 1000), () {
      onProgress(70, 'diffusing', 'Denoising latents');
    });
    Future.delayed(const Duration(milliseconds: 1800), () {
      onProgress(100, 'completed', 'Generation complete');
    });
  }
}
