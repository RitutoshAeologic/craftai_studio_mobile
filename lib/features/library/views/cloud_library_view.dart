import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import '../controllers/library_controller.dart';
import '../widgets/download_paywall_sheet.dart';
import '../views/creation_detail_view.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../shell/controllers/shell_controller.dart';

class CloudLibraryView extends StatelessWidget {
  const CloudLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final LibraryController controller = Get.put(LibraryController());

    return Scaffold(
      body: Obx(() {
        if (controller.myCreations.isEmpty) {
          return AppEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No Creations Yet',
            subtitle: 'Generate your first masterpiece in the Studio canvas.',
            actionLabel: 'Create Now',
            onAction: () => Get.find<ShellController>().switchTab(1),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: controller.myCreations.length,
          itemBuilder: (context, idx) {
            final job = controller.myCreations[idx];
            return GestureDetector(
              onTap: () => Get.to(() => CreationDetailView(job: job)),
              child: Container(
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      AppNetworkImage(
                        imageUrl: (job.previewUrl.isNotEmpty && job.previewUrl.startsWith('http'))
                            ? job.previewUrl
                            : 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop',
                        height: 180.h,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                      ),
                      Positioned(
                        top: 8.h,
                        right: 8.w,
                        child: GestureDetector(
                          onTap: () => _confirmDelete(context, controller, job),
                          child: Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
                            ),
                            child: Icon(Icons.delete_outline_rounded, color: AppColors.accentError, size: 18.sp),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(job.prompt, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp)),
                        SizedBox(height: 10.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: job.isDownloadUnlocked ? AppColors.accentSuccess.withValues(alpha: 0.15) : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                job.isDownloadUnlocked ? 'Unlocked (4K Ready)' : 'Cloud Saved (Free)',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: job.isDownloadUnlocked ? AppColors.accentSuccess : AppColors.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Get.bottomSheet(DownloadPaywallSheet(job: job));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: job.isDownloadUnlocked ? AppColors.accentSuccess : AppColors.primary,
                                foregroundColor: AppColors.white,
                                elevation: 0,
                                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                              ),
                              icon: Icon(
                                job.isDownloadUnlocked ? Icons.check_circle_outline_rounded : Icons.download_rounded,
                                size: 14.sp,
                                color: AppColors.white,
                              ),
                              label: Text(
                                job.isDownloadUnlocked ? 'Re-Download (Free)' : 'Download 4K (2 Cr)',
                                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }),
    );
  }

  void _confirmDelete(BuildContext context, LibraryController controller, dynamic job) {
    Get.dialog(
      Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.accentError.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.delete_forever_rounded, color: AppColors.accentError, size: 28.sp),
              ),
              SizedBox(height: 16.h),
              Text(
                'Delete Creation?',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Text(
                'Permanently remove this creation from your cloud library and storage? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp, height: 1.4),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('Cancel', style: TextStyle(color: AppColors.textPrimary, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        controller.deleteCreation(job);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentError,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      child: Text('Delete', style: TextStyle(color: AppColors.white, fontSize: 12.sp, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
