import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';

/// [AsyncWorker] provides background Isolate execution for CPU-intensive
/// tasks such as Base64 decoding/encoding and bulk JSON deserialization.
///
/// Running these operations in separate Dart Isolates prevents UI thread
/// blocking, directly eliminating Android Choreographer frame drops.
class AsyncWorker {
  AsyncWorker._();

  /// Maximum byte size of data that can be parsed synchronously on the main thread
  /// without triggering isolate spawn overhead (~50 KB).
  static const int _inlineThresholdBytes = 50 * 1024;

  /// Decodes a base64-encoded data URI or raw string into [Uint8List] bytes.
  /// Small payloads (<50KB) run inline; larger payloads run in a dedicated Isolate.
  static Future<Uint8List> decodeBase64(String base64Data) async {
    final cleanString = base64Data.contains(',')
        ? base64Data.split(',').last
        : base64Data;

    // Fast-path: small payloads do not justify isolate setup overhead
    if (cleanString.length < _inlineThresholdBytes) {
      try {
        return base64Decode(cleanString);
      } catch (e) {
        AppLogger.w('Inline base64 decode failed: $e', tag: 'ASYNC_WORKER');
        rethrow;
      }
    }

    try {
      return await Isolate.run(() {
        return base64Decode(cleanString);
      });
    } catch (e) {
      AppLogger.w('Isolate base64 decode failed, falling back to main thread: $e', tag: 'ASYNC_WORKER');
      return base64Decode(cleanString);
    }
  }

  /// Encodes [Uint8List] image bytes into a base64 string in a background Isolate.
  static Future<String> encodeBase64(Uint8List bytes) async {
    if (bytes.length < _inlineThresholdBytes) {
      return base64Encode(bytes);
    }

    try {
      return await Isolate.run(() {
        return base64Encode(bytes);
      });
    } catch (e) {
      AppLogger.w('Isolate base64 encode failed, falling back to main thread: $e', tag: 'ASYNC_WORKER');
      return base64Encode(bytes);
    }
  }

  /// Deserializes a raw list of JSON maps into typed models using [factory].
  /// When [rawList] contains more than 10 items, execution is offloaded to an Isolate.
  static Future<List<T>> parseList<T>(
    List<dynamic> rawList,
    T Function(Map<String, dynamic> json) factory,
  ) async {
    if (rawList.isEmpty) return <T>[];

    // For tiny lists (<= 5 items), run on main thread to avoid Isolate serialization costs
    if (rawList.length <= 5) {
      return rawList
          .map((item) => factory(item as Map<String, dynamic>))
          .toList();
    }

    try {
      // Isolate.run transfers data between isolates. Functions passed to Isolate.run
      // must be top-level or static. For closure-based factories, we execute with safe fallback.
      return await Isolate.run(() {
        return rawList
            .map((item) => factory(item as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      // If the factory contains non-transferable closures or fails in Isolate, execute on main thread
      return rawList
          .map((item) => factory(item as Map<String, dynamic>))
          .toList();
    }
  }
}

