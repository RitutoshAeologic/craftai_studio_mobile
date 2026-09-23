import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:craftai_studio_mobile/core/services/network_service.dart';
import 'package:craftai_studio_mobile/core/network/connectivity_interceptor.dart';

class MockConnectivity implements Connectivity {
  final StreamController<List<ConnectivityResult>> _streamController =
      StreamController<List<ConnectivityResult>>.broadcast();

  List<ConnectivityResult> initialResults = [ConnectivityResult.wifi];

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async {
    return initialResults;
  }

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _streamController.stream;

  void emit(List<ConnectivityResult> results) {
    _streamController.add(results);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockConnectivity mockConnectivity;
  late NetworkService networkService;

  setUp(() async {
    Get.testMode = true;
    mockConnectivity = MockConnectivity();
    networkService = NetworkService(connectivity: mockConnectivity);
    await networkService.init();
    Get.put<NetworkService>(networkService, permanent: true);
  });

  tearDown(() {
    mockConnectivity.dispose();
    Get.reset();
  });

  group('NetworkService Core Lifecycle & Transitions', () {
    test('Initializes with online Wi-Fi connection', () {
      expect(networkService.isOnline, isTrue);
      expect(networkService.isConnected.value, isTrue);
      expect(networkService.connectionType.value, equals(ConnectivityResult.wifi));
      expect(networkService.showOfflineBanner.value, isFalse);
    });

    test('Transitions from Online to Offline updates state and shows offline banner', () async {
      expect(networkService.isOnline, isTrue);

      // Emit network loss
      mockConnectivity.emit([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(networkService.isOnline, isFalse);
      expect(networkService.isConnected.value, isFalse);
      expect(networkService.connectionType.value, equals(ConnectivityResult.none));
      expect(networkService.showOfflineBanner.value, isTrue);
      expect(networkService.showRestoredBanner.value, isFalse);
    });

    test('Transitions from Offline back to Online shows restored banner and auto-hides offline banner', () async {
      // First go offline
      mockConnectivity.emit([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(networkService.isOnline, isFalse);

      // Now restore Wi-Fi
      mockConnectivity.emit([ConnectivityResult.wifi]);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(networkService.isOnline, isTrue);
      expect(networkService.isConnected.value, isTrue);
      expect(networkService.connectionType.value, equals(ConnectivityResult.wifi));
      expect(networkService.showOfflineBanner.value, isFalse);
      expect(networkService.showRestoredBanner.value, isTrue);
    });

    test('dismissOfflineBanner hides the active banner', () async {
      mockConnectivity.emit([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(networkService.showOfflineBanner.value, isTrue);

      networkService.dismissOfflineBanner();
      expect(networkService.showOfflineBanner.value, isFalse);
    });
  });

  group('ConnectivityInterceptor Fast-Fail Tests', () {
    test('Blocks HTTP request immediately with connectionError when offline', () async {
      // Put service in offline state
      mockConnectivity.emit([ConnectivityResult.none]);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(networkService.isOnline, isFalse);

      final dio = Dio();
      dio.interceptors.add(ConnectivityInterceptor());

      DioException? caughtException;
      try {
        await dio.get('https://example.com/api/test');
      } on DioException catch (e) {
        caughtException = e;
      }

      expect(caughtException, isNotNull);
      expect(caughtException!.type, equals(DioExceptionType.connectionError));
      expect(
        caughtException.message,
        contains('No internet connection available'),
      );
    });
  });
}
