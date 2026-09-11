import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import '../controllers/library_controller.dart';

class DownloadPaywallSheet extends StatelessWidget {
  final JobModel job;
  const DownloadPaywallSheet({super.key, required this.job});

  @override
  Widget build(BuildContext context) {
    final LibraryController controller = Get.find<LibraryController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.all(20.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_outlined, color: AppColors.primary, size: 36.sp),
          SizedBox(height: 8.h),
          Text('Lossless 4K Master Export', style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
          SizedBox(height: 6.h),
          Text(
            job.isDownloadUnlocked
                ? 'This image was previously unlocked. Re-downloading is 100% free!'
                : 'Unlock original uncompressed 4K master file without watermark for flat 2 Credits (\$0.20). Re-downloads are always free.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 44.h,
            child: ElevatedButton(
              onPressed: () {
                Get.back();
                controller.unlock4KDownload(job);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
              ),
              child: Text(
                job.isDownloadUnlocked ? 'Download Now (Free \$0.00)' : 'Confirm & Unlock (2 Credits)',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
