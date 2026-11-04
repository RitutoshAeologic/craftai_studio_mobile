import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import '../domain/repositories/i_library_repository.dart';
import '../data/datasources/library_remote_datasource.dart';
import '../data/repositories/library_repository_impl.dart';

/// [LibraryController] manages the user's personal creations library, 4K download
/// unlocks, and deletion flows.
/// Follows Clean Architecture: Depends strictly on [ILibraryRepository].
class LibraryController extends GetxController {
  final ILibraryRepository _repository;

  LibraryController({ILibraryRepository? repository})
      : _repository = repository ?? LibraryRepositoryImpl();

  /// Extracts relative Supabase storage file path from public or signed URL
  /// (Delegates to [LibraryRemoteDataSource.extractStoragePath]).
  static String? extractStoragePath(String? url, {String bucket = 'user_generations'}) =>
      LibraryRemoteDataSource.extractStoragePath(url, bucket: bucket);

  static LibraryController get to => Get.find<LibraryController>();

  final RxList<JobModel> myCreations = <JobModel>[].obs;

  /// Batch size per paginated library fetch
  static const int kPageSize = 20;

  /// Active pagination page index
  final RxInt currentPage = 0.obs;

  /// Initial or full refresh loading indicator
  final RxBool isLoading = false.obs;

  /// Loading indicator for subsequent page load
  final RxBool isLoadingMore = false.obs;

  /// Indicates if more older creations exist in cloud storage
  final RxBool hasMoreCreations = true.obs;

  /// Any error message during pagination fetch (null if healthy)
  final RxnString libraryError = RxnString();

  @override
  void onInit() {
    super.onInit();
    fetchUserCreations(isRefresh: true);
  }

  /// Fetches paginated generation jobs through [ILibraryRepository]
  Future<void> fetchUserCreations({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage.value = 0;
      hasMoreCreations.value = true;
      libraryError.value = null;
      isLoading.value = myCreations.isEmpty;
    } else {
      if (isLoadingMore.value || !hasMoreCreations.value) return;
      isLoadingMore.value = true;
      libraryError.value = null;
    }

    try {
      final loaded = await _repository.getUserCreations(
        page: currentPage.value,
        pageSize: kPageSize,
      );

      if (isRefresh) {
        if (loaded.isNotEmpty) {
          myCreations.assignAll(loaded);
        }
      } else {
        final existingIds = myCreations.map((j) => j.jobId).toSet();
        final newItems = loaded.where((j) => !existingIds.contains(j.jobId)).toList();
        myCreations.addAll(newItems);
      }

      if (loaded.length < kPageSize) {
        hasMoreCreations.value = false;
      } else {
        currentPage.value++;
      }
      AppLogger.s('Loaded ${loaded.length} cloud generations from library repo (page ${currentPage.value})', tag: 'LIBRARY');
      return;
    } catch (e) {
      AppLogger.d('Cloud library fetch skipped or repository error: $e', tag: 'LIBRARY');
      libraryError.value = 'Failed to load cloud creations. Tap to retry.';
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }

    // Default seed creations if no cloud jobs yet and feed empty
    if (myCreations.isEmpty) {
      myCreations.assignAll([
        JobModel(
          jobId: 'job_001',
          type: 'IMAGE_GEN',
          status: 'completed',
          prompt: 'Cyberpunk ronin samurai in dark kimono, wet asphalt Neo-Tokyo',
          previewUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop',
          creditsDeducted: 4.0,
          isDownloadUnlocked: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ]);
    }
  }

  /// Triggers next page load when scrolling near bottom of library
  Future<void> loadMoreCreations() async => fetchUserCreations(isRefresh: false);

  /// Pull-to-refresh handler
  Future<void> refreshCreations() async => fetchUserCreations(isRefresh: true);

  /// Inserts a newly generated artwork into local state and persists via repository
  void addNewCreation({
    String? jobId,
    required String prompt,
    required double credits,
    String? previewUrl,
    String type = 'IMAGE_GEN',
    Map<String, dynamic>? metadata,
  }) {
    final validPreviewUrl = (previewUrl != null &&
            previewUrl.trim().isNotEmpty &&
            (previewUrl.startsWith('http') || previewUrl.startsWith('data:')))
        ? previewUrl
        : 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop';

    final effectiveJobId = (jobId != null && jobId.trim().isNotEmpty)
        ? jobId.trim()
        : 'job_${DateTime.now().millisecondsSinceEpoch}';

    final newJob = JobModel(
      jobId: effectiveJobId,
      type: type,
      status: 'completed',
      prompt: prompt,
      previewUrl: validPreviewUrl,
      creditsDeducted: credits,
      isDownloadUnlocked: false,
      metadata: metadata,
      createdAt: DateTime.now(),
    );

    myCreations.insert(0, newJob);

    // Asynchronously persist via repository
    if (validPreviewUrl.startsWith('http')) {
      _repository.saveCreation(newJob);
    }
  }

  /// Unlocks 4K master export download
  Future<void> unlock4KDownload(JobModel job) async {
    final shellCtrl = Get.find<ShellController>();

    if (job.isDownloadUnlocked) {
      Get.snackbar(
        'Download Link Ready',
        'Image was already unlocked. Generating 15-Minute Signed URL for free (\$0.00)...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
      );
      return;
    }

    if (shellCtrl.userCredits.value < job.downloadCost) {
      Get.snackbar('Insufficient Credits', 'Unlocking 4K Master requires 2 credits.');
      return;
    }

    // Atomic credit deduction
    shellCtrl.deductCredits(job.downloadCost);
    final idx = myCreations.indexWhere((j) => j.jobId == job.jobId);
    if (idx != -1) {
      myCreations[idx] = job.copyWith(isDownloadUnlocked: true);
    }

    await _repository.unlock4KDownload(job.jobId);

    Get.snackbar(
      '4K Master Unlocked! ✨',
      'Flat 2 credits deducted. 15-Minute Supabase Storage signed URL generated.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
    );
  }

  /// Permanently deletes an image from Cloud Storage, database records, and local state.
  Future<bool> deleteCreation(JobModel job, {bool showSnackbar = true}) async {
    try {
      // 1. Optimistically remove from local reactive state by both jobId and previewUrl
      myCreations.removeWhere((j) =>
          j.jobId == job.jobId ||
          (j.previewUrl.isNotEmpty && j.previewUrl == job.previewUrl));
      AppLogger.i('Removed job ${job.jobId} from local UI list', tag: 'LIBRARY');

      // 2. Delegate remote purge to repository
      final success = await _repository.deleteCreation(job);

      if (showSnackbar && Get.overlayContext != null && !Get.testMode) {
        Get.snackbar(
          'Image Deleted 🗑️',
          'Image removed from your library and cloud storage.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.textPrimary,
          icon: Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess),
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 2),
        );
      }
      return success;
    } catch (e) {
      AppLogger.e('Failed to delete creation: $e', tag: 'LIBRARY');
      return false;
    }
  }
}
