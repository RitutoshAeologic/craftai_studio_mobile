import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../controllers/studio_controller.dart';

/// [StudioPromptInspectorSheet] provides complete lifecycle transparency:
/// 1. What user typed (Raw initial draft)
/// 2. What Gemini refined (AI master prompt + negative prompt)
/// 3. What was sent for image generation (Exact FLUX.1/GPU dispatch payload)
/// 4. What prompt the user sees in UI & Library
class StudioPromptInspectorSheet extends StatelessWidget {
  const StudioPromptInspectorSheet({super.key, required this.controller});

  final StudioController controller;

  static void show(BuildContext context, StudioController controller) {
    Get.bottomSheet(
      StudioPromptInspectorSheet(controller: controller),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied! 📋',
      '$label copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusRound)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimens.spacingXl,
        AppDimens.spacingMd,
        AppDimens.spacingXl,
        AppDimens.spacingXxl,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
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
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: AppDimens.vSpacingLg),

            // Header
            Row(
              children: [
                Container(
                  width: 38.w,
                  height: 38.h,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Icon(Icons.manage_search_rounded, color: AppColors.primary, size: 20.sp),
                ),
                SizedBox(width: AppDimens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Prompt Lifecycle Inspector', style: AppTextStyles.h3),
                      SizedBox(height: AppDimens.vSpacingXxs),
                      Text(
                        'Transparent audit of your prompt across all 4 stages',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppDimens.vSpacingLg),

            // Scrollable Timeline Cards
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // STAGE 1: What User Typed
                    Obx(() {
                      final typed = controller.userTypedPrompt.value.isNotEmpty
                          ? controller.userTypedPrompt.value
                          : controller.promptController.text;
                      return _buildStageCard(
                        stageNumber: '1',
                        icon: Icons.edit_note_rounded,
                        stageTitle: 'What You Typed (Raw Draft)',
                        badgeText: '${typed.length} chars',
                        badgeColor: AppColors.secondary,
                        content: typed.isEmpty ? '(No prompt typed yet)' : typed,
                        actionLabel: 'Restore to Input',
                        onAction: typed.isNotEmpty
                            ? () {
                                controller.restoreUserTypedPrompt();
                                Get.back();
                              }
                            : null,
                        onCopy: typed.isNotEmpty ? () => _copyToClipboard(typed, 'Raw Draft') : null,
                      );
                    }),

                    SizedBox(height: AppDimens.vSpacingLg),

                    // STAGE 2: What Gemini Refined
                    Obx(() {
                      final refined = controller.geminiRefinedPrompt.value;
                      final negative = controller.geminiNegativePrompt.value;
                      final engine = controller.geminiModelUsed.value.isNotEmpty
                          ? controller.geminiModelUsed.value
                          : 'Gemini 2.5 Flash';

                      return _buildStageCard(
                        stageNumber: '2',
                        icon: Icons.auto_awesome,
                        stageTitle: 'What Gemini Refined (AI Master)',
                        badgeText: engine,
                        badgeColor: AppColors.primary,
                        content: refined.isNotEmpty
                            ? refined
                            : '(Tap "✨ Enhance" on the studio bar to see Gemini\'s expanded master prompt)',
                        subContentLabel: negative.isNotEmpty ? 'Negative Prompt Filter:' : null,
                        subContent: negative.isNotEmpty ? negative : null,
                        onCopy: refined.isNotEmpty ? () => _copyToClipboard(refined, 'Refined Prompt') : null,
                      );
                    }),

                    SizedBox(height: AppDimens.vSpacingLg),

                    // STAGE 3: What Sent for Generation
                    Obx(() {
                      final dispatched = controller.lastDispatchedPrompt.value;
                      final model = controller.lastDispatchedModel.value;
                      final dims = controller.lastDispatchedDimensions.value;

                      return _buildStageCard(
                        stageNumber: '3',
                        icon: Icons.rocket_launch_outlined,
                        stageTitle: 'Sent to Image AI (FLUX.1 Engine)',
                        badgeText: model.isNotEmpty ? '$model • $dims' : 'Awaiting Dispatch',
                        badgeColor: AppColors.accentWarning,
                        content: dispatched.isNotEmpty
                            ? dispatched
                            : '(Tap "Generate" to inspect the exact GPU worker payload sent to FLUX.1)',
                        onCopy: dispatched.isNotEmpty ? () => _copyToClipboard(dispatched, 'Dispatched Payload') : null,
                      );
                    }),

                    SizedBox(height: AppDimens.vSpacingLg),

                    // STAGE 4: What User Sees in UI & Library
                    Obx(() {
                      final visible = controller.promptLength.value > 0
                          ? controller.promptController.text
                          : '(Empty)';
                      return _buildStageCard(
                        stageNumber: '4',
                        icon: Icons.visibility_outlined,
                        stageTitle: 'What You See in Studio & Library',
                        badgeText: 'Active Canvas',
                        badgeColor: AppColors.accentSuccess,
                        content: visible,
                        onCopy: visible.isNotEmpty ? () => _copyToClipboard(visible, 'Studio Visible Prompt') : null,
                      );
                    }),

                    SizedBox(height: AppDimens.vSpacingXl),
                  ],
                ),
              ),
            ),

            // Close Button
            AppButton(
              label: 'Close Inspector',
              isOutlined: true,
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStageCard({
    required String stageNumber,
    required IconData icon,
    required String stageTitle,
    required String badgeText,
    required Color badgeColor,
    required String content,
    String? subContentLabel,
    String? subContent,
    String? actionLabel,
    VoidCallback? onAction,
    VoidCallback? onCopy,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                width: 22.w,
                height: 22.h,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                ),
                alignment: Alignment.center,
                child: Text(
                  stageNumber,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: AppDimens.spacingSm),
              Expanded(
                flex: 3,
                child: Text(
                  stageTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12.sp,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Flexible(
                flex: 2,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                    border: Border.all(color: badgeColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    badgeText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionXs.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: AppDimens.vSpacingSm),

          // Content Text
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppDimens.spacingSm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.border.withOpacity(0.5)),
            ),
            child: SelectableText(
              content,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),

          // Optional Sub-content (e.g. Negative Prompt)
          if (subContent != null && subContent.isNotEmpty) ...[
            SizedBox(height: AppDimens.vSpacingXs),
            if (subContentLabel != null)
              Text(
                subContentLabel,
                style: AppTextStyles.captionXs.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppDimens.spacingSm),
              decoration: BoxDecoration(
                color: AppColors.accentWarning.withOpacity(0.04),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                border: Border.all(color: AppColors.accentWarning.withOpacity(0.2)),
              ),
              child: SelectableText(
                subContent,
                style: AppTextStyles.captionXs.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ),
          ],

          SizedBox(height: AppDimens.vSpacingSm),

          // Action Buttons (using Wrap for zero overflow on compact devices)
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 4.h,
              children: [
                if (actionLabel != null && onAction != null)
                  TextButton.icon(
                    onPressed: onAction,
                    icon: Icon(Icons.undo_rounded, size: 14.sp, color: AppColors.primary),
                    label: Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                if (onCopy != null)
                  TextButton.icon(
                    onPressed: onCopy,
                    icon: Icon(Icons.copy_rounded, size: 14.sp, color: AppColors.textSecondary),
                    label: Text(
                      'Copy',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
