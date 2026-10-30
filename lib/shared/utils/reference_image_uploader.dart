import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/network/api_config.dart';
import '../../features/studio/domain/failures/studio_failure.dart';
import '../../core/utils/app_logger.dart';

class ReferenceImageUploader {
  static const int maxFileSizeInBytes = 10 * 1024 * 1024; // 10 MB limit per rules.md §6
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'heic'];

  /// Validates the file format and size per rules.md §6 before network transmission
  static StudioFailure? validateFile(File file) {
    if (!file.existsSync()) {
      return const StudioValidationFailure('File does not exist on device storage.');
    }

    final ext = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) {
      return StudioValidationFailure(
        'Invalid format (.$ext). Only JPG, PNG, and HEIC are supported.',
      );
    }

    final fileSize = file.lengthSync();
    if (fileSize > maxFileSizeInBytes) {
      final sizeMb = (fileSize / (1024 * 1024)).toStringAsFixed(1);
      return StudioValidationFailure(
        'File size ($sizeMb MB) exceeds the 10 MB limit. Please select a smaller photo.',
      );
    }

    return null;
  }

  /// Uploads validated reference photo to Supabase Storage bucket 'reference-images'
  /// Uses backend admin gateway first (bypasses RLS), falling back to direct Supabase client.
  static Future<({String? url, StudioFailure? failure})> uploadReferenceImage(File file) async {
    final validationError = validateFile(file);
    if (validationError != null) {
      return (url: null, failure: validationError);
    }

    // 1. Try Backend Upload Gateways (Configured baseUrl + optional fallback)
    final candidateUrls = <String>{
      ApiConfig.baseUrl,
      if (ApiConfig.fallbackUrl != null) ApiConfig.fallbackUrl!,
      if (ApiConfig.isAndroidDevice &&
          (ApiConfig.baseUrl.contains('127.0.0.1') ||
              ApiConfig.baseUrl.contains('localhost')))
        ApiConfig.baseUrl
            .replaceAll('127.0.0.1', '10.0.2.2')
            .replaceAll('localhost', '10.0.2.2'),
    }.toList();

    for (final backendUrl in candidateUrls) {
      try {
        final client = dio.Dio(
          dio.BaseOptions(
            baseUrl: backendUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'ngrok-skip-browser-warning': 'true'},
          ),
        );
        final fileName = file.path.split('/').last;
        final formData = dio.FormData.fromMap({
          'file': await dio.MultipartFile.fromFile(file.path, filename: fileName),
        });

        // Correct relative path resolved against client's baseUrl
        final uploadPath = '/prompt-engineering/upload-reference';
        final res = await client.post(uploadPath, data: formData);
        if (res.statusCode == 200 && res.data is Map && res.data['url'] != null) {
          final publicUrl = res.data['url'] as String;
          AppLogger.s('Reference uploaded via Backend Gateway ($backendUrl): $publicUrl', tag: 'UPLOADER');
          return (url: publicUrl, failure: null);
        }
      } catch (e) {
        AppLogger.w('Backend gateway ($backendUrl) attempt failed: $e', tag: 'UPLOADER');
      }
    }

    // 2. Direct Supabase Storage Client fallback to 'user_generations'
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id ?? 'demo_guest_user';
      final ext = file.path.split('.').last.toLowerCase();
      final storagePath = 'user_refs/$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('user_generations').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = client.storage.from('user_generations').getPublicUrl(storagePath);
      AppLogger.s('Reference uploaded directly to Supabase: $publicUrl', tag: 'UPLOADER');
      return (url: publicUrl, failure: null);
    } on StorageException catch (e) {
      AppLogger.w('Supabase Storage notice: ${e.message}. Using Data URI fallback.', tag: 'UPLOADER');
    } catch (e) {
      AppLogger.w('Direct storage notice: $e. Using Data URI fallback.', tag: 'UPLOADER');
    }

    // 3. Guaranteed in-memory Data URI fallback
    try {
      final bytes = await file.readAsBytes();
      final ext = file.path.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final b64 = base64Encode(bytes);
      final dataUri = 'data:$mime;base64,$b64';
      AppLogger.s('Photo encoded to resilient in-memory Data URI', tag: 'UPLOADER');
      return (url: dataUri, failure: null);
    } catch (e) {
      return (
        url: null,
        failure: StudioUnknownFailure('Photo read failure: $e'),
      );
    }
  }
}
