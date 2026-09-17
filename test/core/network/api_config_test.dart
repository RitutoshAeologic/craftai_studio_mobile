import 'package:flutter_test/flutter_test.dart';
import 'package:craftai_studio_mobile/core/network/api_config.dart';

void main() {
  group('ApiConfig Unit Tests', () {
    test('baseUrl returns non-empty string and defaults correctly', () {
      expect(ApiConfig.baseUrl, isNotEmpty);
      expect(ApiConfig.baseUrl.endsWith('/api/v1'), isTrue);
    });

    test('fallbackUrl defaults to null when not injected in environment', () {
      expect(ApiConfig.fallbackUrl, isNull);
    });

    test('isLocalHost returns true for 127.0.0.1 default base URL', () {
      expect(ApiConfig.isLocalHost, isTrue);
    });

    test('buildWsGenerationUrl formats ws endpoint correctly for task ID', () {
      const taskId = 'task_test_123';
      final wsUrl = ApiConfig.buildWsGenerationUrl(taskId);

      expect(wsUrl.startsWith('ws://') || wsUrl.startsWith('wss://'), isTrue);
      expect(wsUrl.contains('/prompt-engineering/ws/generation/$taskId'), isTrue);
    });
  });
}
