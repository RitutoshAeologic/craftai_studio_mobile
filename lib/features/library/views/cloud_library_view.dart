import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import '../controllers/library_controller.dart';
import '../widgets/download_paywall_sheet.dart';

class CloudLibraryView extends StatelessWidget {
  const CloudLibraryView({super.key});

  @override
  Widget build(BuildContext context) {
    final LibraryController controller = Get.put(LibraryController());

    return Scaffold(
      body: Obx(() => ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: controller.myCreations.length,
        itemBuilder: (context, idx) {
          final job = controller.myCreations[idx];
          return Container(
            margin: EdgeInsets.only(bottom: 16.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                  child: CachedNetworkImage(
                    imageUrl: job.previewUrl,
                    height: 180.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
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
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                            ),
                            icon: const Icon(Icons.download, size: 14),
                            label: Text(job.isDownloadUnlocked ? 'Re-Download (Free)' : 'Download 4K (2 Cr)', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      )),
    );
  }
}
