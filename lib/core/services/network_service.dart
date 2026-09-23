import 'dart:async';
import 'dart:io' show InternetAddress, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import '../utils/app_logger.dart';

/// Centralized reactive network connectivity service.
///
/// Registered as a permanent [GetxService] via:
/// `Get.putAsync<NetworkService>(() => NetworkService().init(), permanent: true);`
///
/// Conforms to rules.md §1 & §6: All network states are observable,
/// non-blocking, and provide clear technical diagnostic logging.
class NetworkService extends GetxService {
  NetworkService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Global singleton accessor.
  static NetworkService get to => Get.find<NetworkService>();

  /// Reactive observable boolean indicating whether the device has an active network connection.
  final RxBool isConnected = true.obs;

  /// Reactive observable of the current primary connection type.
  final Rx<ConnectivityResult> connectionType = ConnectivityResult.wifi.obs;

  /// Reactive observable indicating if internet reachability verification is currently in-flight.
  final RxBool isCheckingReachability = false.obs;

  /// Reactive observable indicating whether the offline banner should be visible.
  final RxBool showOfflineBanner = false.obs;

  /// Reactive observable indicating whether the "back online" banner is actively showing.
  final RxBool showRestoredBanner = false.obs;

  /// Convenient boolean getter.
  bool get isOnline => isConnected.value;

  /// Initializes connectivity listeners and checks the initial network state.
  Future<NetworkService> init() async {
    try {
      final initialResults = await _connectivity.checkConnectivity();
      _updateConnectionStatus(initialResults);
    } catch (e, st) {
      AppLogger.e('Failed to read initial connectivity: $e', tag: 'NETWORK', error: e, stackTrace: st);
      // Optimistically default to true to prevent blocking initial offline-tolerant UI
      isConnected.value = true;
    }

    _subscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChanged,
      onError: (error, st) {
        AppLogger.e('Connectivity stream error: $error', tag: 'NETWORK', error: error, stackTrace: st);
      },
    );

    return this;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }

  /// Handles incoming connectivity changes from the OS.
  Future<void> _handleConnectivityChanged(List<ConnectivityResult> results) async {
    final wasOnline = isConnected.value;
    _updateConnectionStatus(results);

    if (wasOnline && !isConnected.value) {
      // Transition from Online -> Offline
      AppLogger.w('Device network lost (Offline)', tag: 'NETWORK');
      showRestoredBanner.value = false;
      showOfflineBanner.value = true;
    } else if (!wasOnline && isConnected.value) {
      // Transition from Offline -> Online
      AppLogger.s('Device network restored (Online via ${connectionType.value.name})', tag: 'NETWORK');
      showOfflineBanner.value = false;
      showRestoredBanner.value = true;

      // Auto-hide the "Back Online" success pill after 2.5 seconds
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (isConnected.value) {
          showRestoredBanner.value = false;
        }
      });
    }
  }

  /// Evaluates the list of [ConnectivityResult] reported by the platform.
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      isConnected.value = false;
      connectionType.value = ConnectivityResult.none;
      return;
    }

    // Determine the primary active interface
    if (results.contains(ConnectivityResult.wifi)) {
      connectionType.value = ConnectivityResult.wifi;
    } else if (results.contains(ConnectivityResult.mobile)) {
      connectionType.value = ConnectivityResult.mobile;
    } else if (results.contains(ConnectivityResult.ethernet)) {
      connectionType.value = ConnectivityResult.ethernet;
    } else if (results.contains(ConnectivityResult.vpn)) {
      connectionType.value = ConnectivityResult.vpn;
    } else {
      connectionType.value = results.first;
    }

    isConnected.value = true;
  }

  /// Optional active verification checking if the device can actually resolve external DNS.
  /// Useful to detect captive portals or dead Wi-Fi routers.
  Future<bool> checkInternetReachability({String host = 'google.com'}) async {
    if (kIsWeb) return isConnected.value;

    isCheckingReachability.value = true;
    try {
      final results = await InternetAddress.lookup(host)
          .timeout(const Duration(milliseconds: 3000));
      final reachable = results.isNotEmpty && results.first.rawAddress.isNotEmpty;
      isConnected.value = reachable;
      if (!reachable) {
        showOfflineBanner.value = true;
        showRestoredBanner.value = false;
      }
      return reachable;
    } on SocketException catch (_) {
      isConnected.value = false;
      showOfflineBanner.value = true;
      showRestoredBanner.value = false;
      return false;
    } on TimeoutException catch (_) {
      AppLogger.w('DNS reachability check timed out for $host', tag: 'NETWORK');
      return false;
    } catch (e) {
      AppLogger.w('Unexpected error during DNS reachability check: $e', tag: 'NETWORK');
      return false;
    } finally {
      isCheckingReachability.value = false;
    }
  }

  /// Manually dismiss the offline banner if the user taps dismiss.
  void dismissOfflineBanner() {
    showOfflineBanner.value = false;
  }
}
