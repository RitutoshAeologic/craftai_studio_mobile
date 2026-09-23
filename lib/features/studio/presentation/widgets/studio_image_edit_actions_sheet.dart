import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/widgets/download_paywall_sheet.dart';
import 'package:craftai_studio_mobile/features/remix/views/remix_chat_view.dart';

/// [StudioImageEditActionsSheet] presents the MeiGen 4-option image editing modal.
/// Options:
/// 1. "✨ Describe edits" -> Loads into Studio as image1 with "Edit image1 as follows: "
/// 2. "✂️ Remove Background" -> Direct transparent cutout
/// 3. "🔄 Use prompt" -> Loads prompt text directly into Studio
/// 4. "4K+ Upscale 4K" -> Opens Lossless 4K Paywall
class StudioImageEditActionsSheet extends StatelessWidget {
  final JobModel job;

  const StudioImageEditActionsSheet({super.key, required this.job});

  static void show(BuildContext context, JobModel job) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StudioImageEditActionsSheet(job: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final studioCtrl = Get.find<StudioController>();
    final shellCtrl = Get.find<ShellController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Pill Handle
            Container(
              width: 38.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 16.h),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
            ),

            // Option 1: Describe edits
            _buildActionItem(
              icon: Icons.auto_awesome,
              iconColor: AppColors.primary,
              title: 'Describe edits',
              subtitle: studioCtrl.freeEditAttemptsRemaining.value > 0
                  ? 'Condition on image1 • ${studioCtrl.freeEditAttemptsRemaining.value} Free Attempts Remaining'
                  : 'Condition on image1 with prompt deltas',
              badge: studioCtrl.freeEditAttemptsRemaining.value > 0 ? 'Free' : null,
              onTap: () {
                Get.back();
                studioCtrl.loadForImageEdit(imageUrl: job.previewUrl, initialPrompt: job.prompt);
                shellCtrl.switchTab(1);
              },
            ),

            // Option 2: Remix in Lab (Conversational Chat)
            _buildActionItem(
              icon: Icons.shuffle_rounded,
              iconColor: AppColors.purpleAccent,
              title: 'Remix in Lab (Chat)',
              subtitle: 'Conversational style & lighting tuning anchored to this creation',
              badge: 'Remix Lab',
              onTap: () {
                Get.back();
                Get.to(
                  () => const RemixChatView(),
                  arguments: {
                    'anchorImageUrl': job.previewUrl,
                    'sourceType': 'library',
                    'initialPrompt': job.prompt,
                    'authorName': 'Your Creation',
                  },
                  transition: Transition.rightToLeft,
                );
              },
            ),

            // Option 2: Remove Background
            _buildActionItem(
              icon: Icons.content_cut_rounded,
              iconColor: AppColors.textPrimary,
              title: 'Remove Background',
              subtitle: 'Zero-token local CPU transparent PNG cutout',
              onTap: () {
                Get.back();
                shellCtrl.switchTab(2); // AI Tools
              },
            ),

            // Option 3: Use prompt
            _buildActionItem(
              icon: Icons.sync_rounded,
              iconColor: AppColors.textPrimary,
              title: 'Use prompt',
              subtitle: 'Load raw text prompt into Studio canvas',
              onTap: () {
                Get.back();
                studioCtrl.loadPromptText(job.prompt);
                shellCtrl.switchTab(1);
              },
            ),

            // Option 4: Upscale 4K
            _buildActionItem(
              icon: Icons.high_quality_rounded,
              iconColor: AppColors.textPrimary,
              title: 'Upscale 4K',
              subtitle: job.isDownloadUnlocked ? 'Lossless export unlocked' : 'Unlock uncompressed 4K master file (2 Cr)',
              onTap: () {
                Get.back();
                Get.bottomSheet(DownloadPaywallSheet(job: job));
              },
            ),

            SizedBox(height: 12.h),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 46.h,
              child: TextButton(
                onPressed: () => Get.back(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.surfaceLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusRound)),
                ),
                child: Text(
                  'Cancel',
                  style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(icon, size: 22.sp, color: iconColor),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 14.sp, color: AppColors.textPrimary),
                      ),
                      if (badge != null) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: Text(
                            badge,
                            style: AppTextStyles.captionXs.copyWith(
                              color: AppColors.accentSuccess,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18.sp, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
