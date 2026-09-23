import 'dart:io';
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
      'https://craftwork-gizmo-engraved.ngrok-free.dev/api/v1',
      if (ApiConfig.fallbackUrl != null) ApiConfig.fallbackUrl!,
      'http://192.168.68.124:8000/api/v1',
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

        final uploadPath = backendUrl.endsWith('/api/v1')
            ? '/api/v1/prompt-engineering/upload-reference'
            : '/prompt-engineering/upload-reference';
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

    // 2. Direct Supabase Storage Client fallback
    try {
      final client = SupabaseService.client;
      final userId = client.auth.currentUser?.id ?? 'demo_guest_user';
      final ext = file.path.split('.').last.toLowerCase();
      final storagePath = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('reference-images').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final publicUrl = client.storage.from('reference-images').getPublicUrl(storagePath);
      AppLogger.s('Reference uploaded directly to Supabase: $publicUrl', tag: 'UPLOADER');
      return (url: publicUrl, failure: null);
    } on StorageException catch (e) {
      AppLogger.e('Supabase Storage exception: ${e.message}', tag: 'UPLOADER');
      return (
        url: null,
        failure: StudioServerFailure('Storage upload error: ${e.message}'),
      );
    } catch (e) {
      AppLogger.e('Unexpected upload exception: $e', tag: 'UPLOADER');
      return (
        url: null,
        failure: StudioUnknownFailure('Upload error: $e'),
      );
    }
  }
}
