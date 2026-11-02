import 'package:dio/dio.dart';
import '../services/supabase_service.dart';

/// Interceptor that dynamically injects the active Supabase JWT Bearer token
/// into outgoing HTTP requests if the user is signed in.
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    try {
      final token = SupabaseService.client.auth.currentSession?.accessToken;
      if (token != null && token.isNotEmpty && !options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // In offline environments, unit tests, or prior to Supabase init, pass through safely.
    }
    super.onRequest(options, handler);
  }
}

