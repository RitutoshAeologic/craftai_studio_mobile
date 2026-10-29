import 'package:flutter_test/flutter_test.dart';
import 'package:craftai_studio_mobile/core/network/api_config.dart';

void main() {
  group('ApiConfig Unit Tests', () {
    test('baseUrl returns non-empty string and defaults correctly', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl.endsWith('/api/v1'), isTrue);
    });

    test('fallbackUrl returns valid string or null when not injected in environment', () {
      expect(ApiConfig.fallbackUrl, anyOf(isNull, isNotEmpty));
    });

    test('isLocalHost matches whether baseUrl is loopback', () {
      final isLoopback = ApiConfig.baseUrl.contains('127.0.0.1') ||
          ApiConfig.baseUrl.contains('localhost') ||
          ApiConfig.baseUrl.contains('10.0.2.2');
      expect(ApiConfig.isLocalHost, isLoopback);
    });

    test('buildWsGenerationUrl formats ws endpoint correctly for task ID', () {
      const taskId = 'task_test_123';
      final wsUrl = ApiConfig.buildWsGenerationUrl(taskId);

      expect(wsUrl.startsWith('ws://') || wsUrl.startsWith('wss://'), isTrue);
      expect(wsUrl.contains('/ws/generation/$taskId'), isTrue);
    });
  });
}
