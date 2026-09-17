import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import '../controllers/studio_controller.dart';

class StudioModelSheet extends StatelessWidget {
  const StudioModelSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const StudioModelSheet(),
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
                  AppStrings.aiModelTitle,
                  style: AppTextStyles.h3,
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textMuted, size: AppDimens.iconSm),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: AppDimens.vSpacingMd),
            ...controller.availableModels.map((m) {
              return Obx(() {
                final isSel = controller.selectedModel.value == m['id'];
                return GestureDetector(
                  onTap: () {
                    controller.setModel(m['id']!);
                    Get.back();
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: AppDimens.vSpacingSm),
                    padding: EdgeInsets.all(AppDimens.spacingMd),
                    decoration: BoxDecoration(
                      color: isSel ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(
                        color: isSel ? AppColors.primary : AppColors.border,
                        width: isSel ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(m['icon']!, style: TextStyle(fontSize: 18.sp)),
                        SizedBox(width: AppDimens.spacingMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: AppDimens.spacingSm,
                                runSpacing: 2.h,
                                children: [
                                  Text(
                                    m['name']!,
                                    style: AppTextStyles.bodyMediumBold.copyWith(
                                      color: isSel ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                                    ),
                                    child: Text(
                                      m['badge']!,
                                      style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ],
                              ),
                              if (m['desc'] != null) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  m['desc']!,
                                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Text(
                            m['credits']!,
                            style: AppTextStyles.captionBold.copyWith(
                              color: isSel ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              });
            }),
            SizedBox(height: AppDimens.vSpacingMd),
          ],
        ),
      ),
    );
  }
}
