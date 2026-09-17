import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Centralized API and environment configuration for CraftAI Studio mobile.
///
/// Follows rules.md §3: No hardcoded secrets, staging URLs, or ephemeral
/// tunnel domains in source control. All URLs are injected via --dart-define
/// (e.g. `dart_defines/dev.json`).
class ApiConfig {
  ApiConfig._();

  /// The primary FastAPI backend URL.
  ///
  /// Configured via:
  /// `--dart-define=BACKEND_URL=http://127.0.0.1:8000/api/v1`
  /// or inside `dart_defines/dev.json`.
  static String get baseUrl {
    const envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // Default fallback when no environment define is passed
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// Optional remote fallback URL (e.g. an active ngrok tunnel or remote staging server).
  ///
  /// Only used if explicitly supplied via:
  /// `--dart-define=FALLBACK_BACKEND_URL=https://.../api/v1`
  /// Returns null if not provided, preventing noisy requests to dead tunnels.
  static String? get fallbackUrl {
    const envFallback = String.fromEnvironment('FALLBACK_BACKEND_URL');
    return envFallback.trim().isNotEmpty ? envFallback.trim() : null;
  }

  /// Whether the current configured backend targets a local machine loopback.
  static bool get isLocalHost {
    final url = baseUrl.toLowerCase();
    return url.contains('127.0.0.1') || url.contains('localhost') || url.contains('10.0.2.2');
  }

  /// Whether the app is running on a native Android device.
  static bool get isAndroidDevice => !kIsWeb && Platform.isAndroid;

  /// Builds a WebSocket URL for streaming generation progress.
  static String buildWsGenerationUrl(String taskId) {
    final base = baseUrl;
    final wsBase = base
        .replaceFirst('http://', 'ws://')
        .replaceFirst('https://', 'wss://');

    if (wsBase.endsWith('/api/v1')) {
      return '$wsBase/prompt-engineering/ws/generation/$taskId';
    } else if (wsBase.endsWith('/api/v1/')) {
      return '${wsBase}prompt-engineering/ws/generation/$taskId';
    }
    return '$wsBase/api/v1/prompt-engineering/ws/generation/$taskId';
  }
}
