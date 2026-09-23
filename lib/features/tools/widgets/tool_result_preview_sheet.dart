import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/shared/widgets/before_after_slider.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/remix/views/remix_chat_view.dart';

class ToolResultPreviewSheet extends StatelessWidget {
  final String title;
  final String resultImageUrl;
  final String? originalImageUrl;
  final double creditsUsed;
  final String? badgeText;
  final bool enableBeforeAfter;

  const ToolResultPreviewSheet({
    super.key,
    required this.title,
    required this.resultImageUrl,
    this.originalImageUrl,
    this.creditsUsed = 0.0,
    this.badgeText,
    this.enableBeforeAfter = false,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String resultImageUrl,
    String? originalImageUrl,
    double creditsUsed = 0.0,
    String? badgeText,
    bool enableBeforeAfter = false,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ToolResultPreviewSheet(
        title: title,
        resultImageUrl: resultImageUrl,
        originalImageUrl: originalImageUrl,
        creditsUsed: creditsUsed,
        badgeText: badgeText,
        enableBeforeAfter: enableBeforeAfter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showSplit = enableBeforeAfter &&
        originalImageUrl != null &&
        originalImageUrl!.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
            ),

            // Header Bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                title,
                                style: AppTextStyles.h2.copyWith(fontSize: 18.sp),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.accentSuccess.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess, size: 12.sp),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'Saved to Library',
                                    style: TextStyle(
                                      fontSize: 10.sp,
                                      color: AppColors.accentSuccess,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (badgeText != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            badgeText!,
                            style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20.sp),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.border, height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Media Viewer
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: showSplit
                          ? BeforeAfterSlider(
                              beforeImageUrl: originalImageUrl!,
                              afterImageUrl: resultImageUrl,
                              beforeLabel: 'ORIGINAL',
                              afterLabel: 'AI RESULT',
                              height: 320,
                            )
                          : AspectRatio(
                              aspectRatio: 1.0,
                              child: CachedNetworkImage(
                                imageUrl: resultImageUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Container(
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.surface,
                                  child: const Center(
                                    child: Icon(Icons.broken_image, color: AppColors.textMuted),
                                  ),
                                ),
                              ),
                            ),
                    ),

                    SizedBox(height: 16.h),

                    // Quick Stats Pill
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.bolt, color: AppColors.primary, size: 16.sp),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    creditsUsed > 0
                                        ? '${creditsUsed.toStringAsFixed(0)} Credits consumed'
                                        : 'Zero-Token • Free',
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: creditsUsed > 0 ? AppColors.textPrimary : AppColors.accentSuccess,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            showSplit ? 'Drag slider' : 'Full HD',
                            style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Primary Action: ⚡ Remix in Lab (Chat)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.to(
                          () => const RemixChatView(),
                          arguments: {
                            'anchorImageUrl': resultImageUrl,
                            'initialPrompt': 'Refine: $title',
                            'sourceType': 'tool_generated',
                          },
                        );
                      },
                      child: Container(
                        height: 48.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                          ),
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.white, size: 18.sp),
                            SizedBox(width: 8.w),
                            Flexible(
                              child: Text(
                                '⚡ Remix in Lab (Chat)',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // Secondary Actions: Open in Studio Canvas & Dismiss
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              ),
                            ),
                            icon: Icon(Icons.palette_outlined, size: 16.sp, color: AppColors.textPrimary),
                            label: Text(
                              'Studio Canvas',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (Get.isRegistered<StudioController>()) {
                                Get.find<StudioController>().addReferenceImage(resultImageUrl);
                              }
                              if (Get.isRegistered<ShellController>()) {
                                ShellController.to.switchTab(1); // Studio
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              elevation: 0,
                            ),
                            icon: Icon(Icons.check, size: 16.sp, color: AppColors.accentSuccess),
                            label: Text(
                              'Done',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
