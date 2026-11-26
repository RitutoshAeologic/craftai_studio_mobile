import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import '../../domain/models/ai_model_item.dart';
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.aiModelTitle,
                        style: AppTextStyles.h3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Obx(() {
                        final taskLabel = switch (controller.activeStudioTask) {
                          'image_edit' => 'Mode: Image Editing',
                          'face_lock_remix' => 'Mode: Face-Lock Remix',
                          _ => 'Mode: Text-to-Image',
                        };
                        return Text(
                          taskLabel,
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        );
                      }),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: AppDimens.iconSm),
                      tooltip: 'Refresh models',
                      onPressed: () => controller.fetchAvailableModels(),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textMuted, size: AppDimens.iconSm),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: AppDimens.vSpacingMd),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: Obx(() {
                final models = controller.catalogModels;
                final currentTask = controller.activeStudioTask;
                final selectedKey = controller.selectedModel.value;

                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: models
                        .map((m) => _buildModelCard(controller, m, selectedKey, currentTask))
                        .toList(),
                  ),
                );
              }),
            ),
            SizedBox(height: AppDimens.vSpacingSm),
          ],
        ),
      ),
    );
  }

  Widget _buildModelCard(
    StudioController controller,
    AiModelItem model,
    String selectedKey,
    String activeTask,
  ) {
    final isSel = selectedKey == model.modelKey;
    final supportsTask = model.supportsTask(activeTask);
    final isSelectable = model.isAvailable && supportsTask;

    final disabledReason = !model.isAvailable
        ? 'API key not configured'
        : (!supportsTask ? 'Unsupported in $activeTask mode' : null);

    return Opacity(
      opacity: isSelectable ? 1.0 : 0.48,
      child: GestureDetector(
        onTap: isSelectable
            ? () {
                controller.setModel(model.modelKey);
                Get.back();
              }
            : null,
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
              Text(model.resolvedIcon, style: TextStyle(fontSize: 18.sp)),
              SizedBox(width: AppDimens.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppDimens.spacingXs,
                      runSpacing: 4.h,
                      children: [
                        Text(
                          model.displayName,
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: isSel ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        // Active mode badge (Local Engine vs HD Cloud)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: model.isPaidCloud
                                ? AppColors.primary.withValues(alpha: 0.14)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                            border: Border.all(
                              color: model.isPaidCloud
                                  ? AppColors.primary.withValues(alpha: 0.4)
                                  : AppColors.border,
                            ),
                          ),
                          child: Text(
                            model.modeBadgeLabel,
                            style: AppTextStyles.captionXs.copyWith(
                              color: model.isPaidCloud ? AppColors.primary : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Capability tags (Fast, Face-Lock, Edit, HD)
                        ...model.capabilityTags.map(
                          (tag) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                            ),
                            child: Text(
                              tag,
                              style: AppTextStyles.captionXs.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 9.5.sp,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (disabledReason != null) ...[
                      SizedBox(height: 3.h),
                      Text(
                        disabledReason,
                        style: AppTextStyles.captionXs.copyWith(color: AppColors.accentWarning),
                      ),
                    ] else if (model.description != null && model.description!.isNotEmpty) ...[
                      SizedBox(height: 2.h),
                      Text(
                        model.description!,
                        style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: AppDimens.spacingSm),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                ),
                child: Text(
                  model.creditsLabel,
                  style: AppTextStyles.captionBold.copyWith(
                    color: isSel ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
