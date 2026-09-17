import 'dart:async';
import 'package:dio/dio.dart';
import '../../domain/failures/studio_failure.dart';
import '../../domain/models/prompt_expand_model.dart';
import '../../domain/models/prompt_compile_model.dart';
import '../../domain/models/generation_dispatch_model.dart';
import '../../domain/repositories/i_studio_repository.dart';
import '../datasources/studio_remote_datasource.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/utils/app_logger.dart';

class StudioRepositoryImpl implements IStudioRepository {
  final StudioRemoteDataSource _remoteDataSource;

  StudioRepositoryImpl({StudioRemoteDataSource? remoteDataSource})
      : _remoteDataSource = remoteDataSource ?? StudioRemoteDataSource();

  StudioFailure _mapDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.transformTimeout:
        return const StudioTimeoutFailure('The generation server took too long to respond. Credits have been refunded — please tap retry.');
      case DioExceptionType.connectionError:
        if (ApiConfig.isLocalHost && ApiConfig.isAndroidDevice) {
          return const StudioNetworkFailure(
            'Cannot connect to local backend (127.0.0.1:8000). On physical Android devices, run "adb reverse tcp:8000 tcp:8000" on your Mac, or check that your backend server is running.',
          );
        } else if (ApiConfig.isLocalHost) {
          return StudioNetworkFailure(
            'Cannot connect to local backend at ${ApiConfig.baseUrl}. Please check that your backend server is running.',
          );
        }
        return const StudioNetworkFailure(
          'Network connection failed. Unable to reach generation server. Please check your internet connection and try again.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 400) {
          return const StudioValidationFailure('Invalid prompt or generation parameters sent to server. Please adjust your prompt.');
        } else if (statusCode == 422) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null && data['message'].toString().isNotEmpty) {
            final msg = data['message'].toString();
            if (msg.toLowerCase().contains('at most') || msg.toLowerCase().contains('too long')) {
              return const StudioValidationFailure('Your prompt exceeds the maximum length limit. Please shorten it slightly and try again.');
            }
            return StudioValidationFailure(msg);
          } else if (data is Map && data['detail'] is List && (data['detail'] as List).isNotEmpty) {
            final firstError = (data['detail'] as List).first;
            if (firstError is Map && firstError['msg'] != null) {
              final rawMsg = firstError['msg'].toString();
              if (rawMsg.toLowerCase().contains('string_too_long') || rawMsg.contains('at most')) {
                return const StudioValidationFailure('Your prompt exceeds the maximum length limit. Please shorten it slightly and try again.');
              }
              return StudioValidationFailure(rawMsg);
            }
          } else if (data is Map && data['detail'] is String) {
            final detailStr = data['detail'].toString();
            if (detailStr.toLowerCase().contains('string_too_long')) {
              return const StudioValidationFailure('Your prompt exceeds the maximum length limit. Please shorten it slightly and try again.');
            }
            return StudioValidationFailure(detailStr);
          }
          return const StudioModerationFailure('Your prompt was flagged by the content moderation safety policy. Please adjust sensitive keywords.');
        } else if (statusCode == 429) {
          return const StudioRateLimitFailure('Server is busy with high demand right now. Please wait a moment before trying again.');
        } else if (statusCode == 404) {
          return const StudioServerFailure('Generation endpoint not found on server (404). Please verify backend routes.');
        } else if (statusCode != null && statusCode >= 500) {
          return StudioServerFailure('Generation server encountered a temporary glitch ($statusCode). Credits have been refunded — please tap retry.');
        }
        return StudioUnknownFailure('Server response error: ${e.response?.statusMessage ?? 'Unknown error'}. Credits refunded.');
      case DioExceptionType.cancel:
        return const StudioUnknownFailure('Generation request was cancelled.');
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const StudioNetworkFailure('Network communication error. Please check your internet connection.');
    }
  }

  @override
  Future<StudioResult<PromptExpandModel>> expandPrompt(
    String rawPrompt, {
    String? starterChip,
    String aspectRatio = '1:1',
    String aiEngine = 'groq',
  }) async {
    try {
      final data = await _remoteDataSource.expandPrompt(
        rawPrompt: rawPrompt,
        starterChip: starterChip,
        aspectRatio: aspectRatio,
        aiEngine: aiEngine,
      );
      AppLogger.s('Prompt expanded via ${data.modelUsed} | Length: ${data.masterPrompt.length} chars', tag: 'STUDIO_REPO');
      return (data: data, failure: null);
    } on DioException catch (e) {
      AppLogger.w('expandPrompt API exception (${e.type}): ${e.message}', tag: 'STUDIO_REPO');
      return (
        data: null,
        failure: _mapDioException(e),
      );
    } catch (e, st) {
      AppLogger.e('Unexpected error expanding prompt', tag: 'STUDIO_REPO', error: e, stackTrace: st);
      return (
        data: null,
        failure: StudioUnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<StudioResult<PromptCompileModel>> compileChatDelta({
    required String basePrompt,
    required String userInstruction,
    int turnCount = 1,
    String aiEngine = 'groq',
  }) async {
    try {
      final data = await _remoteDataSource.compileChatDelta(
        basePrompt: basePrompt,
        userInstruction: userInstruction,
        turnCount: turnCount,
        aiEngine: aiEngine,
      );
      AppLogger.s('Chat delta compiled via ${data.modelUsed} | Added: ${data.addedTags}', tag: 'STUDIO_REPO');
      return (data: data, failure: null);
    } on DioException catch (e) {
      AppLogger.w('compileChatDelta API exception (${e.type}): ${e.message}', tag: 'STUDIO_REPO');
      return (
        data: null,
        failure: _mapDioException(e),
      );
    } catch (e, st) {
      AppLogger.e('Unexpected error compiling chat delta', tag: 'STUDIO_REPO', error: e, stackTrace: st);
      return (
        data: null,
        failure: StudioUnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<StudioResult<String>> applyQuickTool({
    required String imageId,
    required String action,
    required String targetPreset,
  }) async {
    try {
      final taskId = await _remoteDataSource.applyQuickTool(
        imageId: imageId,
        action: action,
        targetPreset: targetPreset,
      );
      AppLogger.s('Quick tool applied: action=$action, targetPreset=$targetPreset', tag: 'STUDIO_REPO');
      return (data: taskId, failure: null);
    } on DioException catch (e) {
      AppLogger.w('applyQuickTool API exception (${e.type}): ${e.message}', tag: 'STUDIO_REPO');
      return (
        data: null,
        failure: _mapDioException(e),
      );
    } catch (e, st) {
      AppLogger.e('Unexpected error applying quick tool', tag: 'STUDIO_REPO', error: e, stackTrace: st);
      return (
        data: null,
        failure: StudioUnknownFailure(e.toString()),
      );
    }
  }

  @override
  Future<StudioResult<String>> removeBackground({required String imageUrl}) async {
    try {
      final cutoutUrl = await _remoteDataSource.removeBackground(imageUrl: imageUrl);
      if (cutoutUrl != null && cutoutUrl.isNotEmpty) {
        AppLogger.s('Background removed cleanly: $cutoutUrl', tag: 'STUDIO_REPO');
        return (data: cutoutUrl, failure: null);
      }
      return (data: null, failure: const StudioServerFailure('Background removal returned empty result.'));
    } on DioException catch (e) {
      AppLogger.w('removeBackground API exception (${e.type}): ${e.message}', tag: 'STUDIO_REPO');
      return (data: null, failure: _mapDioException(e));
    } catch (e, st) {
      AppLogger.e('Unexpected error in removeBackground', tag: 'STUDIO_REPO', error: e, stackTrace: st);
      return (data: null, failure: StudioUnknownFailure(e.toString()));
    }
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
    try {
      final data = await _remoteDataSource.dispatchGeneration(
        prompt: prompt,
        characterId: characterId,
        faceReferenceUrls: faceReferenceUrls,
        width: width,
        height: height,
        model: model,
        remixedFromPromptId: remixedFromPromptId,
      );
      AppLogger.s('Generation dispatched: taskId=${data.taskId} | Tier=${data.tier} | DirectUrl=${data.directImageUrl}', tag: 'STUDIO_REPO');
      return (data: data, failure: null);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError) {
        AppLogger.w('dispatchGeneration connection error at ${ApiConfig.baseUrl}: ${e.message}', tag: 'STUDIO_REPO');
      } else {
        AppLogger.w('dispatchGeneration API exception (${e.type}): ${e.message}', tag: 'STUDIO_REPO');
      }
      return (
        data: null,
        failure: _mapDioException(e),
      );
    } catch (e, st) {
      AppLogger.e('Unexpected error dispatching generation', tag: 'STUDIO_REPO', error: e, stackTrace: st);
      return (
        data: null,
        failure: StudioUnknownFailure(e.toString()),
      );
    }
  }

  @override
  StreamSubscription? listenToGenerationProgress({
    required String taskId,
    required void Function(int progress, String status, String message) onProgress,
  }) {
    return _remoteDataSource.listenToGenerationProgress(
      taskId: taskId,
      onProgress: onProgress,
    );
  }
}
