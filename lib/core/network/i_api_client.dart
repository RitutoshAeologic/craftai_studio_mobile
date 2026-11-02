import 'dart:io';
import 'package:dio/dio.dart';

/// Abstract contract for HTTP operations in CraftAI Studio Mobile.
///
/// Adheres to Clean Architecture & the Dependency Inversion Principle (DIP):
/// High-level data repositories depend strictly on this abstraction rather than
/// low-level third-party vendor SDKs.
abstract class IApiClient {
  /// The underlying [Dio] engine for direct low-level compatibility.
  Dio get dio;

  /// Executes a type-safe GET request.
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Executes a type-safe POST request.
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Executes a type-safe PUT request.
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Executes a type-safe DELETE request.
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  /// Executes a high-performance multipart file upload with optional progress callbacks.
  Future<Response<T>> uploadFile<T>(
    String path,
    File file, {
    String fileFieldName = 'file',
    Map<String, dynamic>? extraFields,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  });
}

