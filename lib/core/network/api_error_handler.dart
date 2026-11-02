import 'package:dio/dio.dart';
import 'api_config.dart';
import 'api_error.dart';
import '../../features/studio/domain/failures/studio_failure.dart';

/// Centralized, enterprise-grade Error Normalizer for CraftAI Studio Mobile.
///
/// Decouples low-level Transport / HTTP errors (timeouts, offline, tunnel 503)
/// from Backend Application / Business logic errors (400, 401, 422, 500).
class ApiErrorHandler {
  ApiErrorHandler._();

  /// Parses any thrown error into a strongly-typed [AppNetworkException].
  static AppNetworkException parse(Object error) {
    if (error is AppNetworkException) return error;

    if (error is! DioException) {
      return ServerException(error.toString(), code: 'UNEXPECTED');
    }

    final e = error;
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;
    final responseStr = data?.toString() ?? '';

    // ── 1. Gateway / Tunnel Proxy Failures (502 / 503 / 504) ─────────────────
    if (statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504 ||
        responseStr.contains('Tunnel Unavailable') ||
        responseStr.contains('503 Service Unavailable')) {
      return TunnelUnavailableException(
        'Backend tunnel connection is currently unavailable. Please verify that your local backend or tunnel is running.',
        statusCode ?? 503,
      );
    }

    // ── 2. Transport Layer Errors (Timeouts & Connection Failures) ───────────
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkTimeoutException(
          'Network request timed out. The server took too long to respond — please tap retry.',
        );

      case DioExceptionType.connectionError:
        if (ApiConfig.isAndroidDevice &&
            (ApiConfig.baseUrl.contains('127.0.0.1') || ApiConfig.baseUrl.contains('localhost'))) {
          return const ConnectionException(
            'Cannot connect to local backend (127.0.0.1:8000). On physical Android devices, run "adb reverse tcp:8000 tcp:8000" in your terminal, or check your Wi-Fi backend URL.',
          );
        }
        return const ConnectionException(
          'Network connection failed. Unable to reach backend server. Please check your internet connection.',
        );

      case DioExceptionType.cancel:
        return const ServerException('Request was cancelled.', code: 'CANCELLED');

      case DioExceptionType.badResponse:
        // Handle HTTP Status codes from FastAPI
        if (statusCode == 401) {
          return const AuthTokenException();
        } else if (statusCode == 429) {
          return const RateLimitException();
        } else if (statusCode == 400 || statusCode == 422) {
          final message = _extractFastApiMessage(data) ??
              'Invalid prompt or studio parameters. Please verify your input.';
          return ServerException(
            message,
            code: statusCode == 422 ? 'VALIDATION_422' : 'BAD_REQUEST_400',
            statusCode: statusCode,
            responseData: data,
          );
        } else if (statusCode == 404) {
          return ServerException(
            'Requested API endpoint was not found on server (404).',
            code: 'NOT_FOUND_404',
            statusCode: 404,
          );
        } else if (statusCode != null && statusCode >= 500) {
          final serverMsg = _extractFastApiMessage(data);
          final friendly = serverMsg ?? 'Backend server encountered a temporary error ($statusCode). Please tap retry.';
          return ServerException(
            friendly,
            code: 'SERVER_ERROR_$statusCode',
            statusCode: statusCode,
            responseData: data,
          );
        }
        break;

      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return const ConnectionException(
          'Network communication error. Please check your internet connection.',
        );
    }

    return ServerException(e.message ?? 'Unknown network error', code: 'UNKNOWN', responseData: data);
  }

  /// Extracts clean human-readable error messages from FastAPI / Pydantic responses.
  static String? _extractFastApiMessage(dynamic data) {
    if (data is! Map) return null;

    // Check for standard CraftAI custom message
    if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
      final msg = data['message'].toString().trim();
      if (msg.toLowerCase().contains('at most') || msg.toLowerCase().contains('too long')) {
        return 'Your prompt exceeds the maximum length limit. Please shorten it slightly.';
      }
      return msg;
    }

    // Check for FastAPI Pydantic detail list: [{"loc": ["body", "prompt"], "msg": "..."}]
    if (data['detail'] is List && (data['detail'] as List).isNotEmpty) {
      final first = (data['detail'] as List).first;
      if (first is Map && first['msg'] != null) {
        final rawMsg = first['msg'].toString().trim();
        if (rawMsg.toLowerCase().contains('string_too_long') || rawMsg.contains('at most')) {
          return 'Your prompt exceeds the maximum length limit. Please shorten it slightly.';
        }
        return rawMsg;
      }
    }

    // Check for simple string detail
    if (data['detail'] is String && (data['detail'] as String).trim().isNotEmpty) {
      return (data['detail'] as String).trim();
    }

    return null;
  }

  /// Bridges [AppNetworkException] cleanly to [StudioFailure] for domain repositories.
  static StudioFailure toStudioFailure(Object error) {
    final parsed = parse(error);

    return switch (parsed) {
      ConnectionException e => StudioNetworkFailure(e.message),
      NetworkTimeoutException e => StudioTimeoutFailure(e.message),
      TunnelUnavailableException e => StudioNetworkFailure(e.message),
      AuthTokenException e => StudioServerFailure(e.message, code: 'UNAUTHORIZED_401'),
      RateLimitException e => StudioRateLimitFailure(e.message),
      ServerException e when e.statusCode == 422 => StudioValidationFailure(e.message),
      ServerException e when e.statusCode == 400 => StudioValidationFailure(e.message),
      ServerException e => StudioServerFailure(e.message, code: e.code ?? 'SERVER_ERROR'),
    };
  }
}
