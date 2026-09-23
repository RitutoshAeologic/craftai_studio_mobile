import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../services/network_service.dart';
import '../utils/app_logger.dart';

/// Interceptor that checks if the device is currently offline before initiating
/// an HTTP request. Rejects immediately without waiting for OS socket timeouts.
class ConnectivityInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (Get.isRegistered<NetworkService>() && !NetworkService.to.isOnline) {
      AppLogger.w(
        'Request blocked pre-flight (Device offline): ${options.method} ${options.uri}',
        tag: 'NETWORK',
      );

      return handler.reject(
        DioException(
          requestOptions: options,
          error: 'No active internet connection',
          type: DioExceptionType.connectionError,
          message: 'No internet connection available. Please check your Wi-Fi or mobile data.',
        ),
      );
    }

    super.onRequest(options, handler);
  }
}
