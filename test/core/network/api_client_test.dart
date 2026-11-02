import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:craftai_studio_mobile/core/network/api_client.dart';
import 'package:craftai_studio_mobile/core/network/api_config.dart';
import 'package:craftai_studio_mobile/core/network/auth_interceptor.dart';
import 'package:craftai_studio_mobile/core/network/connectivity_interceptor.dart';
import 'package:craftai_studio_mobile/core/network/dio_logging_interceptor.dart';
import 'package:craftai_studio_mobile/core/network/network_fallback_interceptor.dart';

class _FakeCustomApiClient implements IApiClient {
  @override
  Dio get dio => Dio(BaseOptions(baseUrl: 'https://fake.test'));

  @override
  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 200);
  }

  @override
  Future<Response<T>> post<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 201);
  }

  @override
  Future<Response<T>> put<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 200);
  }

  @override
  Future<Response<T>> delete<T>(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options, CancelToken? cancelToken}) async {
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 204);
  }

  @override
  Future<Response<T>> uploadFile<T>(String path, File file, {String fileFieldName = 'file', Map<String, dynamic>? extraFields, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress}) async {
    return Response<T>(requestOptions: RequestOptions(path: path), statusCode: 200);
  }
}

void main() {
  setUp(() {
    ApiClient.resetInstance();
  });

  tearDown(() {
    ApiClient.resetInstance();
  });

  group('ApiClient Clean Architecture & Contract Tests', () {
    test('ApiClient implements IApiClient contract', () {
      final client = ApiClient.instance;
      expect(client, isA<IApiClient>());
    });

    test('instance returns the same singleton instance across multiple calls', () {
      final client1 = ApiClient.instance;
      final client2 = ApiClient.instance;

      expect(identical(client1, client2), isTrue);
      expect(identical(client1.dio, client2.dio), isTrue);
    });

    test('client static getter returns the singleton dio instance', () {
      expect(identical(ApiClient.client, ApiClient.instance.dio), isTrue);
    });

    test('dio configuration adheres to required base options and tunnel headers', () {
      final dio = ApiClient.client;

      expect(dio.options.baseUrl, equals(ApiConfig.baseUrl));
      expect(dio.options.connectTimeout, equals(const Duration(seconds: 15)));
      expect(dio.options.receiveTimeout, equals(const Duration(seconds: 60)));
      expect(dio.options.sendTimeout, equals(const Duration(seconds: 30)));

      expect(dio.options.headers['Content-Type'], equals('application/json'));
      expect(dio.options.headers['Accept'], equals('application/json'));
      expect(dio.options.headers['Bypass-Tunnel-Reminder'], equals('true'));
      expect(dio.options.headers['ngrok-skip-browser-warning'], equals('true'));
    });

    test('interceptors chain includes Connectivity, Auth, Fallback, and Logging interceptors', () {
      final dio = ApiClient.client;
      final interceptorTypes = dio.interceptors.map((i) => i.runtimeType).toList();

      expect(interceptorTypes.contains(ConnectivityInterceptor), isTrue);
      expect(interceptorTypes.contains(AuthInterceptor), isTrue);
      expect(interceptorTypes.contains(NetworkFallbackInterceptor), isTrue);
      expect(interceptorTypes.contains(DioLoggingInterceptor), isTrue);
    });

    test('setMockInstance allows injecting any IApiClient implementation for 100% test decoupling', () async {
      final fake = _FakeCustomApiClient();
      ApiClient.setMockInstance(fake);

      expect(identical(ApiClient.instance, fake), isTrue);
      final res = await ApiClient.instance.post('/test');
      expect(res.statusCode, equals(201));

      ApiClient.resetInstance();
      final freshClient = ApiClient.instance;
      expect(freshClient.dio.options.baseUrl, equals(ApiConfig.baseUrl));
    });
  });
}
