import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';

class LibraryController extends GetxController {
  final RxList<JobModel> myCreations = <JobModel>[
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
    JobModel(
      jobId: 'job_002',
      type: 'IMAGE_GEN',
      status: 'completed',
      prompt: 'Futuristic hypercar in rainy city reflecting cyan lights',
      previewUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?w=600&auto=format&fit=crop',
      creditsDeducted: 4.0,
      isDownloadUnlocked: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ].obs;

  void addNewCreation({required String prompt, required double credits}) {
    myCreations.insert(
      0,
      JobModel(
        jobId: 'job_${DateTime.now().millisecondsSinceEpoch}',
        type: 'IMAGE_GEN',
        status: 'completed',
        prompt: prompt,
        previewUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop',
        creditsDeducted: credits,
        isDownloadUnlocked: false,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> unlock4KDownload(JobModel job) async {
    final shellCtrl = Get.find<ShellController>();

    if (job.isDownloadUnlocked) {
      // Idempotent: Free re-download
      Get.snackbar(
        'Download Link Ready',
        'Image was already unlocked. Generating 15-Minute Signed URL for free (\$0.00)...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF151D2F),
        colorText: const Color(0xFF00F2FE),
      );
      return;
    }

    if (shellCtrl.userCredits.value < job.downloadCost) {
      Get.snackbar('Insufficient Credits', 'Unlocking 4K Master requires 2 credits.');
      return;
    }

    // Atomic deduction
    shellCtrl.deductCredits(job.downloadCost);
    final idx = myCreations.indexWhere((j) => j.jobId == job.jobId);
    if (idx != -1) {
      myCreations[idx] = job.copyWith(isDownloadUnlocked: true);
    }

    Get.snackbar(
      '4K Master Unlocked! ✨',
      'Flat 2 credits deducted. 15-Minute Supabase Storage signed URL generated.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF151D2F),
      colorText: const Color(0xFF00F2FE),
    );
  }
}
