import 'package:dio/dio.dart';
import 'package:craftai_studio_mobile/core/network/api_client.dart';
import 'package:craftai_studio_mobile/core/services/i_supabase_service.dart';
import 'package:craftai_studio_mobile/core/services/supabase_service.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/core/utils/async_worker.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';

/// Remote data source responsible for all network, database, and cloud storage
/// operations related to the Cloud Library.
class LibraryRemoteDataSource {
  final ISupabaseService _supabase;
  final IApiClient _apiClient;

  LibraryRemoteDataSource({
    ISupabaseService? supabase,
    IApiClient? apiClient,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _apiClient = apiClient ?? ApiClient.instance;

  /// Extracts relative Supabase storage file path from public or signed URL
  static String? extractStoragePath(String? url, {String bucket = 'user_generations'}) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();
    final bucketMarker = '$bucket/';
    if (clean.contains(bucketMarker)) {
      return clean.split(bucketMarker).last.split('?').first.replaceAll(RegExp(r'^/+'), '');
    }
    const knownFolders = [
      'generations/',
      'ai_backgrounds/',
      'ai_expands/',
      'upscaled_4k/',
      'product_details/',
      'marketing_posters/',
      'presets/',
      'user_refs/',
    ];
    for (final folder in knownFolders) {
      if (clean.contains(folder)) {
        final idx = clean.indexOf(folder);
        return clean.substring(idx).split('?').first;
      }
    }
    return null;
  }

  /// Fetches a paginated slice of user generation jobs from Supabase `jobs` table
  /// with background isolate deserialization.
  Future<List<JobModel>> fetchUserCreations({
    required int page,
    required int pageSize,
  }) async {
    final user = _supabase.currentUser;
    if (user == null) return <JobModel>[];

    final from = page * pageSize;
    final to = from + pageSize - 1;

    final res = await _supabase
        .from('jobs')
        .select('*')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .range(from, to);

    return await AsyncWorker.parseList(
      res as List,
      (r) => JobModel.fromJson(r),
    );
  }

  /// Persists a new creation job to Supabase `jobs` table
  Future<void> saveCreation(JobModel job) async {
    final user = _supabase.currentUser;
    if (user == null) return;

    await _supabase.from('jobs').insert({
      'job_id': job.jobId,
      'user_id': user.id,
      'type': job.type,
      'tool_applied': job.type.toLowerCase(),
      'status': 'completed',
      'prompt': job.prompt,
      'prompt_text': job.prompt,
      'preview_url': job.previewUrl,
      'preview_image_url': job.previewUrl,
      'image_url': job.previewUrl,
      'credits_deducted': job.creditsDeducted,
      'is_download_unlocked': false,
      'metadata': job.metadata ?? {},
      'created_at': DateTime.now().toIso8601String(),
    });
    AppLogger.s('Persisted generation ${job.jobId} to Supabase jobs table', tag: 'LIBRARY_DS');
  }

  /// Purges a creation across Backend API, Supabase Storage bucket, and `jobs` table
  Future<bool> deleteCreation(JobModel job) async {
    final storagePath = extractStoragePath(job.previewUrl);

    // 1. Call Backend API endpoint
    try {
      await _apiClient.delete(
        '/prompt-engineering/library/${job.jobId}',
        queryParameters: {
          if (job.previewUrl.isNotEmpty) 'image_url': job.previewUrl,
        },
        options: Options(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      AppLogger.s('Backend library delete API purged ${job.jobId}', tag: 'LIBRARY_DS');
    } catch (apiErr) {
      AppLogger.d('Backend library delete API skipped or offline: $apiErr', tag: 'LIBRARY_DS');
    }

    // 2. Direct Supabase Storage purge
    try {
      if (storagePath != null && storagePath.isNotEmpty) {
        await _supabase.storage.from('user_generations').remove([storagePath]);
        AppLogger.s('Purged $storagePath from Supabase user_generations bucket', tag: 'LIBRARY_DS');
      }
    } catch (storageErr) {
      AppLogger.d('Storage delete skipped: $storageErr', tag: 'LIBRARY_DS');
    }

    // 3. Direct Supabase `jobs` table record deletion
    try {
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(job.jobId);
      if (isUuid) {
        await _supabase
            .from('jobs')
            .delete()
            .or('job_id.eq.${job.jobId},id.eq.${job.jobId}');
      } else {
        await _supabase
            .from('jobs')
            .delete()
            .eq('job_id', job.jobId);
      }

      // 3b. Fallback deletion by preview_url if row used a different job_id alias
      if (job.previewUrl.isNotEmpty && job.previewUrl.startsWith('http')) {
        try {
          await _supabase
              .from('jobs')
              .delete()
              .or('preview_url.eq.${job.previewUrl},preview_image_url.eq.${job.previewUrl}');
        } catch (_) {}
      }

      AppLogger.s('Deleted job ${job.jobId} from Supabase jobs table', tag: 'LIBRARY_DS');
    } catch (dbErr) {
      AppLogger.d('Direct Supabase delete skipped or pending migration: $dbErr', tag: 'LIBRARY_DS');
    }

    return true;
  }

  /// Updates download unlock status in `jobs` table
  Future<bool> unlock4KDownload(String jobId) async {
    try {
      final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(jobId);
      if (isUuid) {
        await _supabase.from('jobs').update({
          'is_download_unlocked': true,
        }).or('job_id.eq.$jobId,id.eq.$jobId');
      } else {
        await _supabase.from('jobs').update({
          'is_download_unlocked': true,
        }).eq('job_id', jobId);
      }
      return true;
    } catch (e) {
      AppLogger.d('Cloud 4K unlock sync skipped: $e', tag: 'LIBRARY_DS');
      return false;
    }
  }
}
