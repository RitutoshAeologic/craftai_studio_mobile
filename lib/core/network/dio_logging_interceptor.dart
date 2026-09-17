import 'package:dio/dio.dart';
import '../utils/app_logger.dart';

/// Interceptor that automatically logs all Dio HTTP requests, responses, and errors to the terminal
class DioLoggingInterceptor extends Interceptor {
  static const String _startTimeKey = '_craftai_request_start_time';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startTimeKey] = DateTime.now().millisecondsSinceEpoch;

    AppLogger.logRequest(
      method: options.method,
      url: options.uri.toString(),
      headers: options.headers,
      body: options.data,
      queryParameters: options.queryParameters,
    );

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = response.requestOptions.extra[_startTimeKey] as int? ?? DateTime.now().millisecondsSinceEpoch;
    final durationMs = DateTime.now().millisecondsSinceEpoch - startTime;

    AppLogger.logResponse(
      method: response.requestOptions.method,
      url: response.requestOptions.uri.toString(),
      statusCode: response.statusCode ?? 200,
      durationMs: durationMs,
      data: response.data,
    );

    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode;

    AppLogger.logHttpError(
      method: err.requestOptions.method,
      url: err.requestOptions.uri.toString(),
      statusCode: statusCode,
      errorType: err.type.name,
      message: err.message,
      responseData: err.response?.data,
    );

    super.onError(err, handler);
  }
}
