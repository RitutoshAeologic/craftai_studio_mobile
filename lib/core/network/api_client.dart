import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'connectivity_interceptor.dart';
import 'dio_logging_interceptor.dart';
import 'network_fallback_interceptor.dart';
import 'i_api_client.dart';

export 'i_api_client.dart';

/// Concrete, enterprise-grade HTTP Client Singleton for CraftAI Studio Mobile.
///
/// Implements [IApiClient] adhering to Clean Architecture & SOLID Principles:
/// - Reuses a single persistent [HttpClient] connection pool (HTTP Keep-Alive).
/// - Fast-fails offline requests with 0ms socket latency via [ConnectivityInterceptor].
/// - Injects Supabase JWT Bearer authentication tokens dynamically via [AuthInterceptor].
/// - Injects required tunnel headers ('Bypass-Tunnel-Reminder', 'ngrok-skip-browser-warning').
/// - Provides thread-safe, independent per-request timeouts and [CancelToken] guards.
/// - Exposes [@visibleForTesting] hooks for mock [IApiClient] injection.
class ApiClient implements IApiClient {
  final Dio _dio;

  @override
  Dio get dio => _dio;

  ApiClient._({Dio? customDio}) : _dio = customDio ?? _buildDefaultDio();

  /// Creates a test instance with a custom or mocked [Dio] instance.
  @visibleForTesting
  factory ApiClient.withDio(Dio dio) => ApiClient._(customDio: dio);

  static IApiClient? _instance;

  /// Global singleton instance accessor conforming to [IApiClient].
  static IApiClient get instance => _instance ??= ApiClient._();

  /// Convenient static accessor for the underlying [Dio] instance.
  static Dio get client => instance.dio;

  @visibleForTesting
  static void setMockInstance(IApiClient mock) {
    _instance = mock;
  }

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  static Dio _buildDefaultDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Bypass-Tunnel-Reminder': 'true',
          'ngrok-skip-browser-warning': 'true',
        },
      ),
    );

    // 1. Fast-fail when offline
    dio.interceptors.add(ConnectivityInterceptor());

    // 2. Dynamic Supabase Auth header injection
    dio.interceptors.add(AuthInterceptor());

    // 3. Transparent fallback routing on network error
    dio.interceptors.add(NetworkFallbackInterceptor(dio));

    // 4. Centralized request/response/error logger
    dio.interceptors.add(DioLoggingInterceptor());

    return dio;
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fileFieldName = 'file',
    Map<String, dynamic>? extraFields,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      fileFieldName: await MultipartFile.fromFile(file.path, filename: fileName),
      if (extraFields != null) ...extraFields,
    });

    return _dio.post<T>(
      path,
      data: formData,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }
}
