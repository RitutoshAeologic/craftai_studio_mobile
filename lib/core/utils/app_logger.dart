import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Enterprise Production Logger for CraftAI Studio
/// Provides formatted, high-visibility terminal logs with clear categorization.
class AppLogger {
  // ANSI Colors for IDE terminals supporting colored output
  static const String _reset = '\x1B[0m';
  static const String _green = '\x1B[32m';
  static const String _yellow = '\x1B[33m';
  static const String _red = '\x1B[31m';
  static const String _cyan = '\x1B[36m';
  static const String _magenta = '\x1B[35m';
  static const String _bold = '\x1B[1m';

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
  }

  static String _prettyJson(dynamic data) {
    if (data == null) return 'null';
    try {
      if (data is Map || data is List) {
        return const JsonEncoder.withIndent('  ').convert(data);
      }
      if (data is String) {
        try {
          final decoded = jsonDecode(data);
          return const JsonEncoder.withIndent('  ').convert(decoded);
        } catch (_) {
          return data;
        }
      }
      return data.toString();
    } catch (_) {
      return data.toString();
    }
  }

  /// Info log (Cyan)
  static void i(String message, {String tag = 'APP'}) {
    if (!kDebugMode) return;
    debugPrint('$_cyan[$tag ℹ️  ${_timestamp()}]$_reset $message');
  }

  /// Success log (Green)
  static void s(String message, {String tag = 'APP'}) {
    if (!kDebugMode) return;
    debugPrint('$_green$_bold[$tag ✅ ${_timestamp()}]$_reset $message');
  }

  /// Warning log (Yellow)
  static void w(String message, {String tag = 'APP'}) {
    if (!kDebugMode) return;
    debugPrint('$_yellow$_bold[$tag ⚠️  ${_timestamp()}]$_reset $message');
  }

  /// Error log (Red)
  static void e(
    String message, {
    String tag = 'APP',
    dynamic error,
    StackTrace? stackTrace,
  }) {
    if (!kDebugMode) return;
    final sb = StringBuffer();
    sb.writeln('$_red$_bold[$tag ❌ ${_timestamp()}] $message$_reset');
    if (error != null) {
      sb.writeln('$_red  Detail: $error$_reset');
    }
    if (stackTrace != null) {
      final lines = stackTrace.toString().split('\n').take(6).join('\n');
      sb.writeln('$_red  Stack:\n$lines$_reset');
    }
    debugPrint(sb.toString());
  }

  /// Debug / Verbose log (Magenta)
  static void d(String message, {String tag = 'APP'}) {
    if (!kDebugMode) return;
    debugPrint('$_magenta[$tag 🔍 ${_timestamp()}]$_reset $message');
  }

  /// Formatted Outgoing HTTP Request Log
  static void logRequest({
    required String method,
    required String url,
    Map<String, dynamic>? headers,
    dynamic body,
    Map<String, dynamic>? queryParameters,
  }) {
    if (!kDebugMode) return;
    final sb = StringBuffer();
    sb.writeln('$_cyan┌── 🌐 [API REQUEST] $method $url (${_timestamp()})$_reset');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      sb.writeln('$_cyan│ Query: $queryParameters$_reset');
    }
    if (body != null) {
      sb.writeln('$_cyan│ Body: ${_prettyJson(body).replaceAll('\n', '\n$_cyan│ ')}$_reset');
    }
    sb.writeln('$_cyan└───$_reset');
    debugPrint(sb.toString());
  }

  /// Formatted Incoming HTTP Response Log (Success)
  static void logResponse({
    required String method,
    required String url,
    required int statusCode,
    required int durationMs,
    dynamic data,
  }) {
    if (!kDebugMode) return;
    final sb = StringBuffer();
    sb.writeln('$_green┌── ✅ [API RESPONSE $statusCode OK] $durationMs ms | $method $url (${_timestamp()})$_reset');
    if (data != null) {
      sb.writeln('$_green│ Data: ${_prettyJson(data).replaceAll('\n', '\n$_green│ ')}$_reset');
    }
    sb.writeln('$_green└───$_reset');
    debugPrint(sb.toString());
  }

  /// Formatted HTTP Error Log
  static void logHttpError({
    required String method,
    required String url,
    int? statusCode,
    required String errorType,
    String? message,
    dynamic responseData,
  }) {
    if (!kDebugMode) return;
    final sb = StringBuffer();
    sb.writeln('$_red┌── ❌ [API ERROR ${statusCode ?? 'NO_STATUS'}] $errorType | $method $url (${_timestamp()})$_reset');
    if (message != null && message.isNotEmpty) {
      sb.writeln('$_red│ Message: $message$_reset');
    }
    if (responseData != null) {
      sb.writeln('$_red│ Server Response: ${_prettyJson(responseData).replaceAll('\n', '\n$_red│ ')}$_reset');
    }
    sb.writeln('$_red└───$_reset');
    debugPrint(sb.toString());
  }

  /// Formatted Prompt Lifecycle Audit Log (Observability across all 4 stages)
  static void logPromptLifecycle({
    required String userTyped,
    String? geminiRefined,
    String? negativePrompt,
    String? sentForGeneration,
    required String userSees,
    String? model,
    String? engine,
  }) {
    if (!kDebugMode) return;
    final sb = StringBuffer();
    sb.writeln('$_cyan┌── 🔍 [PROMPT LIFECYCLE AUDIT] (${_timestamp()}) ──────────────────────$_reset');
    sb.writeln('$_cyan│ 📝 1. USER TYPED (Raw Draft):$_reset');
    sb.writeln('$_cyan│   "${userTyped.isEmpty ? '<empty>' : userTyped}"$_reset');
    sb.writeln('$_cyan│$_reset');

    if (geminiRefined != null && geminiRefined.isNotEmpty) {
      sb.writeln('$_cyan│ ✨ 2. AI REFINED (${engine ?? 'Gemini 2.5 Flash'}):$_reset');
      sb.writeln('$_cyan│   "$geminiRefined"$_reset');
      if (negativePrompt != null && negativePrompt.isNotEmpty) {
        sb.writeln('$_cyan│   Negative: "$negativePrompt"$_reset');
      }
      sb.writeln('$_cyan│$_reset');
    }

    if (sentForGeneration != null && sentForGeneration.isNotEmpty) {
      sb.writeln('$_cyan│ 🚀 3. SENT TO IMAGE ENGINE (${model ?? 'FLUX.1'}):$_reset');
      sb.writeln('$_cyan│   "$sentForGeneration"$_reset');
      sb.writeln('$_cyan│$_reset');
    }

    sb.writeln('$_cyan│ 👁️ 4. USER SEES IN UI / LIBRARY:$_reset');
    sb.writeln('$_cyan│   "$userSees"$_reset');
    sb.writeln('$_cyan└─── 🏁 [END AUDIT] ──────────────────────────────────────────────$_reset');
    debugPrint(sb.toString());
  }
}
