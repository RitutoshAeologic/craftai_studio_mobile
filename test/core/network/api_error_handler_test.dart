import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:craftai_studio_mobile/core/network/api_error.dart';
import 'package:craftai_studio_mobile/core/network/api_error_handler.dart';
import 'package:craftai_studio_mobile/features/studio/domain/failures/studio_failure.dart';

void main() {
  group('ApiErrorHandler Unit Tests', () {
    test('catches 503 Tunnel Unavailable as TunnelUnavailableException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/prompt-engineering/config'),
        response: Response(
          requestOptions: RequestOptions(path: '/prompt-engineering/config'),
          statusCode: 503,
          data: '503 - Tunnel Unavailable',
        ),
        type: DioExceptionType.badResponse,
      );

      final parsed = ApiErrorHandler.parse(dioException);
      expect(parsed, isA<TunnelUnavailableException>());
      expect(parsed.statusCode, equals(503));
      expect(parsed.message.contains('tunnel'), isTrue);

      final studioFailure = ApiErrorHandler.toStudioFailure(dioException);
      expect(studioFailure, isA<StudioNetworkFailure>());
      expect(studioFailure.message.contains('tunnel'), isTrue);
    });

    test('catches 502 Bad Gateway as TunnelUnavailableException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/prompt-engineering/config'),
        response: Response(
          requestOptions: RequestOptions(path: '/prompt-engineering/config'),
          statusCode: 502,
          data: 'Bad Gateway',
        ),
        type: DioExceptionType.badResponse,
      );

      final parsed = ApiErrorHandler.parse(dioException);
      expect(parsed, isA<TunnelUnavailableException>());
      expect(parsed.statusCode, equals(502));
    });

    test('catches connectionTimeout as NetworkTimeoutException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/prompt-engineering/expand'),
        type: DioExceptionType.connectionTimeout,
      );

      final parsed = ApiErrorHandler.parse(dioException);
      expect(parsed, isA<NetworkTimeoutException>());

      final studioFailure = ApiErrorHandler.toStudioFailure(dioException);
      expect(studioFailure, isA<StudioTimeoutFailure>());
    });

    test('catches 401 Unauthorized as AuthTokenException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/auth/signout'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/auth/signout'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      final parsed = ApiErrorHandler.parse(dioException);
      expect(parsed, isA<AuthTokenException>());
      expect(parsed.statusCode, equals(401));
    });

    test('catches 429 Too Many Requests as RateLimitException', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/generation/dispatch'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/generation/dispatch'),
          statusCode: 429,
        ),
        type: DioExceptionType.badResponse,
      );

      final parsed = ApiErrorHandler.parse(dioException);
      expect(parsed, isA<RateLimitException>());

      final studioFailure = ApiErrorHandler.toStudioFailure(dioException);
      expect(studioFailure, isA<StudioRateLimitFailure>());
    });

    test('extracts custom FastAPI message from 422 validation response', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/generation/dispatch'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/generation/dispatch'),
          statusCode: 422,
          data: {
            'error': 'ValidationError',
            'message': 'Invalid prompt: prompt cannot be empty',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final parsed = ApiErrorHandler.parse(dioException);
      expect(parsed, isA<ServerException>());
      expect(parsed.message, equals('Invalid prompt: prompt cannot be empty'));

      final studioFailure = ApiErrorHandler.toStudioFailure(dioException);
      expect(studioFailure, isA<StudioValidationFailure>());
    });

    test('extracts Pydantic detail list message from 422 validation response', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/api/v1/generation/dispatch'),
        response: Response(
          requestOptions: RequestOptions(path: '/api/v1/generation/dispatch'),
          statusCode: 422,
          data: {
            'detail': [
              {
                'loc': ['body', 'prompt'],
                'msg': 'String should have at most 4000 characters',
                'type': 'string_too_long',
              }
            ],
          },
        ),
        type: DioExceptionType.badResponse,
      );

      final parsed = ApiErrorHandler.parse(dioException);
      expect(parsed, isA<ServerException>());
      expect(parsed.message.contains('exceeds the maximum length limit'), isTrue);
    });
  });
}

