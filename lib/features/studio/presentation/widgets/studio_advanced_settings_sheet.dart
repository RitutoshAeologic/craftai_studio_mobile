import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import '../controllers/studio_controller.dart';

class StudioAdvancedSettingsSheet extends StatelessWidget {
  const StudioAdvancedSettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const StudioAdvancedSettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<StudioController>();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg, vertical: AppDimens.vSpacingLg),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: AppDimens.vSpacingMd),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.studioControls,
                  style: AppTextStyles.h3,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textMuted, size: AppDimens.iconSm),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: AppDimens.vSpacingLg),

            // Batch Count Row
            Container(
              padding: EdgeInsets.all(AppDimens.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.batchCount, style: AppTextStyles.bodyMediumBold),
                        SizedBox(height: AppDimens.vSpacingXxs),
                        Text(
                          'Generate multiple variations',
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppDimens.spacingSm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Obx(() => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove, color: AppColors.textPrimary, size: AppDimens.iconSm),
                          onPressed: controller.batchCount.value > 1
                              ? () => controller.setBatchCount(controller.batchCount.value - 1)
                              : null,
                        ),
                        Text(
                          '${controller.batchCount.value}',
                          style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.primary),
                        ),
                        IconButton(
                          icon: Icon(Icons.add, color: AppColors.textPrimary, size: AppDimens.iconSm),
                          onPressed: controller.batchCount.value < 4
                              ? () => controller.setBatchCount(controller.batchCount.value + 1)
                              : null,
                        ),
                      ],
                    )),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppDimens.vSpacingMd),

            // Seed Lock Row
            Container(
              padding: EdgeInsets.all(AppDimens.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppStrings.seedLock, style: AppTextStyles.bodyMediumBold),
                        SizedBox(height: AppDimens.vSpacingXxs),
                        Text(
                          'Keep generation composition constant',
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: AppDimens.spacingSm),
                  Obx(() => Switch.adaptive(
                    value: controller.isSeedLocked.value,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
                    onChanged: (_) => controller.toggleSeedLock(),
                  )),
                ],
              ),
            ),
            SizedBox(height: AppDimens.vSpacingXl),
          ],
        ),
      ),
    );
  }
}
