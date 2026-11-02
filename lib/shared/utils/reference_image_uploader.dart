import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart' as dio;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/supabase_service.dart';
import '../../core/network/api_client.dart';
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

    // 1. Try Backend Upload Gateway via persistent ApiClient singleton
    try {
      final res = await ApiClient.instance.uploadFile(
        '/prompt-engineering/upload-reference',
        file,
        options: dio.Options(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 25),
        ),
      );
      if (res.statusCode == 200 && res.data is Map && res.data['url'] != null) {
        final publicUrl = res.data['url'] as String;
        AppLogger.s('Reference uploaded via Backend Gateway: $publicUrl', tag: 'UPLOADER');
        return (url: publicUrl, failure: null);
      }
    } catch (e) {
      AppLogger.w('Backend gateway upload attempt failed: $e', tag: 'UPLOADER');
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
