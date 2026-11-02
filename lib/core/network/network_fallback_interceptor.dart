import 'package:dio/dio.dart';
import 'api_config.dart';
import '../utils/app_logger.dart';

/// Interceptor that transparently reroutes failed requests to configured
/// fallback URLs (such as Android emulator 10.0.2.2 or physical LAN Wi-Fi)
/// when primary connection fails due to connectionError or connectionTimeout.
class NetworkFallbackInterceptor extends Interceptor {
  final Dio _dio;

  NetworkFallbackInterceptor(this._dio);

  static const String _retriedKey = '_craftai_fallback_retried';

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final alreadyRetried = err.requestOptions.extra[_retriedKey] == true;
    if (alreadyRetried) {
      return super.onError(err, handler);
    }

    final statusCode = err.response?.statusCode;
    final responseStr = err.response?.data?.toString() ?? '';
    final isTunnelDown = statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        responseStr.contains('Tunnel Unavailable') ||
        responseStr.contains('503 Service Unavailable');

    final isConnectionDead = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout;

    if (isConnectionDead || isTunnelDown) {
      final currentBaseUrl = err.requestOptions.baseUrl;
      final candidateFallbacks = <String>[
        if (ApiConfig.fallbackUrl != null && !currentBaseUrl.contains(ApiConfig.fallbackUrl!))
          ApiConfig.fallbackUrl!,
        if (ApiConfig.isAndroidDevice &&
            (currentBaseUrl.contains('127.0.0.1') || currentBaseUrl.contains('localhost')))
          currentBaseUrl.replaceAll('127.0.0.1', '10.0.2.2').replaceAll('localhost', '10.0.2.2'),
        if (ApiConfig.isAndroidDevice && currentBaseUrl.contains('10.0.2.2'))
          currentBaseUrl.replaceAll('10.0.2.2', '127.0.0.1'),
      ];

      for (final fallbackUrl in candidateFallbacks) {
        if (currentBaseUrl == fallbackUrl) continue;

        try {
          AppLogger.w(
            'Primary network unreachable at $currentBaseUrl. Cascading request to fallback: $fallbackUrl',
            tag: 'NETWORK',
          );

          final retryOptions = Options(
            method: err.requestOptions.method,
            headers: Map<String, dynamic>.from(err.requestOptions.headers),
            responseType: err.requestOptions.responseType,
            contentType: err.requestOptions.contentType,
            receiveTimeout: err.requestOptions.receiveTimeout,
            sendTimeout: err.requestOptions.sendTimeout,
            extra: {
              ...err.requestOptions.extra,
              _retriedKey: true,
            },
          );

          final retryPath = err.requestOptions.path.startsWith('http')
              ? err.requestOptions.path
              : '$fallbackUrl${err.requestOptions.path.startsWith('/') ? '' : '/'}${err.requestOptions.path}';

          final res = await _dio.request(
            retryPath,
            data: err.requestOptions.data,
            queryParameters: err.requestOptions.queryParameters,
            options: retryOptions,
          );

          return handler.resolve(res);
        } catch (_) {
          // If this fallback fails, continue to the next candidate
        }
      }
    }

    super.onError(err, handler);
  }
}

