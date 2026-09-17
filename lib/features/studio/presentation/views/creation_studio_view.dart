import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import '../controllers/studio_controller.dart';
import '../widgets/studio_model_sheet.dart';
import '../widgets/studio_advanced_settings_sheet.dart';
import '../widgets/studio_prompt_engine_sheet.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/credit_cost_chip.dart';

class CreationStudioView extends StatelessWidget {
  const CreationStudioView({super.key});

  @override
  Widget build(BuildContext context) {
    final StudioController controller = Get.isRegistered<StudioController>()
        ? Get.find<StudioController>()
        : Get.put(StudioController());

    final ShellController shellCtrl = Get.isRegistered<ShellController>()
        ? Get.find<ShellController>()
        : Get.put(ShellController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: AppDimens.spacingLg,
            vertical: AppDimens.vSpacingMd,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================================
              // SECTION 1: TOP HEADER & REACTIVE WALLET CREDITS INDICATOR
              // =========================================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppStrings.studioTitle,
                    style: AppTextStyles.h1,
                  ),
                  CreditCostChip(
                    creditsRx: shellCtrl.userCredits,
                    onTap: () => shellCtrl.switchTab(4),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.vSpacingMd),

              // =========================================================================
              // SECTIONS 2 - 5: INTERACTIVE CREATIVE CONFIGURATION (LOCKED DURING GENERATION)
              // =========================================================================
              Obx(() => AbsorbPointer(
                absorbing: controller.isGenerating.value,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: controller.isGenerating.value ? 0.55 : 1.0,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =========================================================================
                      // SECTION 2: INSPIRATION STARTER TEMPLATE PILLS (HORIZONTAL SCROLLER)
                      // =========================================================================
                      SizedBox(
                        height: 32.h,
                        child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: controller.starterTemplates.length,
                  separatorBuilder: (_, __) => SizedBox(width: AppDimens.spacingSm),
                  itemBuilder: (context, index) {
                    final t = controller.starterTemplates[index];
                    return GestureDetector(
                      onTap: () => controller.selectStarterTemplate(t),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(t['icon']!, style: TextStyle(fontSize: 11.sp)),
                            SizedBox(width: 4.w),
                            Text(
                              t['title']!,
                              style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppDimens.vSpacingMd),

              // =========================================================================
              // SECTION 3: HERO PROMPT CANVAS & AI COPILOT / MAGIC ENHANCE TOOLBAR
              // =========================================================================
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                padding: EdgeInsets.all(AppDimens.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Obx(() => TextField(
                      controller: controller.promptController,
                      enabled: !controller.isBusy,
                      maxLines: 4,
                      style: AppTextStyles.bodyMedium,
                      decoration: InputDecoration(
                        hintText: AppStrings.promptInputHint,
                        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    )),
                    Divider(color: AppColors.border.withValues(alpha: 0.5), height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Selected AI Prompt Tool Pill (Tap opens selector sheet)
                        GestureDetector(
                          onTap: () => StudioPromptEngineSheet.show(context),
                          child: Obx(() {
                            final engine = controller.availablePromptEngines.firstWhere(
                              (e) => e['id'] == controller.selectedPromptEngine.value,
                              orElse: () => controller.availablePromptEngines.first,
                            );
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(engine['icon']!, style: TextStyle(fontSize: 11.sp)),
                                  SizedBox(width: 4.w),
                                  Text(
                                    engine['name']!.split(' ').first,
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: AppColors.textPrimary,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                  Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 14.sp),
                                ],
                              ),
                            );
                          }),
                        ),
                        SizedBox(width: 4.w),

                        // Action Controls Toolbar (Flexible + scrollable to prevent overflow on small viewports)
                        Flexible(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            reverse: true,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Obx(() {
                                  if (controller.promptLength.value == 0) return const SizedBox.shrink();
                                  return Text(
                                    '${controller.promptLength.value} chars',
                                    style: AppTextStyles.captionXs.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 10.sp,
                                    ),
                                  );
                                }),
                                SizedBox(width: 2.w),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                                  icon: Obx(() => Icon(
                                    controller.referenceImages.isNotEmpty
                                        ? Icons.photo_library
                                        : Icons.add_photo_alternate_outlined,
                                    color: controller.referenceImages.isNotEmpty
                                        ? AppColors.accentSuccess
                                        : AppColors.primary,
                                    size: 16.sp,
                                  )),
                                  tooltip: 'Add Reference / Face Photo',
                                  onPressed: () => _showReferencePickerSheet(context, controller),
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                                  icon: Icon(Icons.chat_bubble_outline, color: AppColors.copilotAccent, size: 16.sp),
                                  tooltip: AppStrings.btnCopilot,
                                  onPressed: controller.openPromptChatCopilot,
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                                  icon: Icon(Icons.copy_rounded, color: AppColors.textSecondary, size: 16.sp),
                                  tooltip: 'Copy Refined Prompt',
                                  onPressed: controller.copyPromptToClipboard,
                                ),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                                  icon: Icon(Icons.manage_search_rounded, color: AppColors.primary, size: 17.sp),
                                  tooltip: 'Inspect Prompt Lifecycle',
                                  onPressed: () => controller.openPromptInspectorSheet(context),
                                ),
                                SizedBox(width: 4.w),
                                Obx(() {
                                  if (!controller.isImageEditMode.value) return const SizedBox.shrink();
                                  return Container(
                                    margin: EdgeInsets.only(right: 6.w),
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE0E7FF),
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(color: const Color(0xFFC7D2FE)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.edit_note_rounded, color: const Color(0xFF4338CA), size: 12.sp),
                                        SizedBox(width: 2.w),
                                        Text(
                                          'AI Edit',
                                          style: TextStyle(
                                            color: const Color(0xFF4338CA),
                                            fontSize: 10.sp,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                Obx(() {
                                  final isEnhancing = controller.isEnhancing.value;
                                  return GestureDetector(
                                    onTap: isEnhancing ? null : controller.enhancePrompt,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: isEnhancing
                                            ? AppColors.primary.withValues(alpha: 0.08)
                                            : AppColors.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                        border: Border.all(
                                          color: isEnhancing
                                              ? AppColors.primary.withValues(alpha: 0.2)
                                              : AppColors.primary.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isEnhancing)
                                            SizedBox(
                                              width: 11.sp,
                                              height: 11.sp,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: AppColors.primary,
                                              ),
                                            )
                                          else
                                            Icon(Icons.auto_awesome, color: AppColors.primary, size: 12.sp),
                                          SizedBox(width: 4.w),
                                          Text(
                                            isEnhancing ? 'Enhancing...' : AppStrings.btnEnhance,
                                            style: AppTextStyles.captionBold.copyWith(
                                              color: AppColors.primary,
                                              fontSize: 11.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // =========================================================================
              // SECTION 3.5: AI ENHANCED STATUS BADGE (OPTION A: SECRET FORMULA ARMED)
              // =========================================================================
              Obx(() {
                if (!controller.isPromptEnhanced) return const SizedBox.shrink();
                return Container(
                  margin: EdgeInsets.only(top: AppDimens.vSpacingSm),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, color: AppColors.primary, size: 14.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'AI Master Formula Armed • Ready for FLUX generation',
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.primary,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.clearEnhancement,
                        child: Container(
                          padding: EdgeInsets.all(2.w),
                          child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 14.sp),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              // Image Edit Mode Status Pill (MeiGen Parity)
              Obx(() {
                if (!controller.isImageEditMode.value) return const SizedBox.shrink();
                final freeAttempts = controller.freeEditAttemptsRemaining.value;
                return Container(
                  margin: EdgeInsets.only(top: AppDimens.vSpacingSm),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: const Color(0xFF2563EB), size: 14.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          freeAttempts > 0
                              ? 'Image Edit Mode • 5 Free Attempts ($freeAttempts remaining • 0 Cr)'
                              : 'Image Edit Mode • Conditioning on image1',
                          style: AppTextStyles.captionBold.copyWith(
                            color: const Color(0xFF1D4ED8),
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => controller.isImageEditMode.value = false,
                        child: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 14.sp),
                      ),
                    ],
                  ),
                );
              }),

              // =========================================================================
              // SECTION 4: REFERENCE PHOTO INPUT SLOT & ZERO-RETENTION PRIVACY BADGE
              // =========================================================================
              Obx(() {
                if (controller.referenceImages.isEmpty) {
                  return GestureDetector(
                    onTap: () => _showReferencePickerSheet(context, controller),
                    child: Container(
                      margin: EdgeInsets.only(top: AppDimens.vSpacingSm),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 16.sp),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add Image Reference (Face Lock / Style)',
                                  style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Upload photo to lock identity or guide AI style',
                                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, color: AppColors.primary, size: 12.sp),
                                SizedBox(width: 2.w),
                                Text(
                                  'Upload',
                                  style: AppTextStyles.captionXs.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // If images are attached: show thumbnails + "+ Add More" button
                return Container(
                  margin: EdgeInsets.only(top: AppDimens.vSpacingSm),
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.check_circle, color: AppColors.accentSuccess, size: 14.sp),
                              SizedBox(width: 6.w),
                              Text(
                                'Reference Active (${controller.referenceImages.length}/3)',
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          Obx(() {
                            if (controller.isRemovingBackground.value) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 10.w,
                                    height: 10.w,
                                    child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Cutting out...',
                                    style: AppTextStyles.captionXs.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              );
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => controller.removeBackgroundFromReference(0),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceLight,
                                      borderRadius: BorderRadius.circular(4.r),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('✂️', style: TextStyle(fontSize: 9.sp)),
                                        SizedBox(width: 3.w),
                                        Text(
                                          'Remove BG',
                                          style: AppTextStyles.captionXs.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                GestureDetector(
                                  onTap: () => _showReferencePickerSheet(context, controller),
                                  child: Text(
                                    '+ Add More',
                                    style: AppTextStyles.captionXs.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      SizedBox(
                        height: 56.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: controller.referenceImages.length,
                          separatorBuilder: (_, __) => SizedBox(width: AppDimens.spacingSm),
                          itemBuilder: (context, index) {
                            final url = controller.referenceImages[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 56.h,
                                  height: 56.h,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                    child: url.startsWith('http')
                                        ? CachedNetworkImage(
                                            imageUrl: url,
                                            fit: BoxFit.cover,
                                            placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                                            errorWidget: (_, __, ___) => Container(
                                              color: AppColors.surfaceLight,
                                              child: Icon(Icons.person, color: AppColors.textMuted, size: AppDimens.iconSm),
                                            ),
                                          )
                                        : Image.file(
                                            File(url),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: AppColors.surfaceLight,
                                              child: Icon(Icons.person, color: AppColors.textMuted, size: AppDimens.iconSm),
                                            ),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 2.h,
                                  right: 2.w,
                                  child: GestureDetector(
                                    onTap: () => controller.removeReferenceImage(index),
                                    child: Container(
                                      padding: EdgeInsets.all(2.r),
                                      decoration: const BoxDecoration(
                                        color: AppColors.surface,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(Icons.close, color: AppColors.accentError, size: 12.sp),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.shield_outlined, color: AppColors.accentSuccess, size: 11.sp),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              'Zero-Retention Privacy: Photo will be auto-purged from cloud post-generation.',
                              style: AppTextStyles.captionXs.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 9.5.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: AppDimens.vSpacingMd),

              // =========================================================================
              // SECTION 5: MODEL, ASPECT RATIO & QUALITY PARAMETER PILL BAR
              // =========================================================================
              SizedBox(
                height: 38.h,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Model Selector Pill
                    GestureDetector(
                      onTap: () => StudioModelSheet.show(context),
                      child: Obx(() {
                        final m = controller.availableModels.firstWhere(
                          (mod) => mod['id'] == controller.selectedModel.value,
                          orElse: () => controller.availableModels.first,
                        );
                        return Container(
                          margin: EdgeInsets.only(right: AppDimens.spacingSm),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(m['icon']!, style: TextStyle(fontSize: 12.sp)),
                              SizedBox(width: 4.w),
                              Text(
                                m['name']!,
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                              ),
                              Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 14.sp),
                            ],
                          ),
                        );
                      }),
                    ),

                    // Aspect Ratio Pill (Cycle onTap, or tap to choose)
                    GestureDetector(
                      onTap: () => _showAspectRatioSheet(context, controller),
                      child: Obx(() => Container(
                        margin: EdgeInsets.only(right: AppDimens.spacingSm),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.aspect_ratio, color: AppColors.primary, size: 14.sp),
                            SizedBox(width: 4.w),
                            Text(
                              controller.selectedAspectRatio.value,
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                            Icon(Icons.keyboard_arrow_down, color: AppColors.textMuted, size: 14.sp),
                          ],
                        ),
                      )),
                    ),

                    // Resolution Pill (Cycle HD -> 2K -> 4K)
                    GestureDetector(
                      onTap: () {
                        final next = controller.selectedResolution.value == 'HD'
                            ? '2K'
                            : (controller.selectedResolution.value == '2K' ? '4K' : 'HD');
                        controller.setResolution(next);
                      },
                      child: Obx(() => Container(
                        margin: EdgeInsets.only(right: AppDimens.spacingSm),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.high_quality, color: AppColors.textSecondary, size: 14.sp),
                            SizedBox(width: 4.w),
                            Text(
                              controller.selectedResolution.value,
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      )),
                    ),

                    // Reference Photo Pill
                    GestureDetector(
                      onTap: () => _showReferencePickerSheet(context, controller),
                      child: Obx(() => Container(
                        margin: EdgeInsets.only(right: AppDimens.spacingSm),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: controller.referenceImages.isNotEmpty
                              ? AppColors.accentSuccess.withValues(alpha: 0.12)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(
                            color: controller.referenceImages.isNotEmpty ? AppColors.accentSuccess : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.face,
                              color: controller.referenceImages.isNotEmpty ? AppColors.accentSuccess : AppColors.textSecondary,
                              size: 14.sp,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              controller.referenceImages.isEmpty
                                  ? '+ Ref'
                                  : 'Ref (${controller.referenceImages.length}/3)',
                              style: AppTextStyles.captionBold.copyWith(
                                color: controller.referenceImages.isNotEmpty ? AppColors.accentSuccess : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                    ),

                    // More Settings Pill
                    GestureDetector(
                      onTap: () => StudioAdvancedSettingsSheet.show(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune, color: AppColors.textSecondary, size: 14.sp),
                            SizedBox(width: 4.w),
                            Text(
                              'More',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      )),
      SizedBox(height: AppDimens.vSpacingLg),

              // =========================================================================
              // SECTION 6: REAL-TIME GENERATION PROGRESS CARD (WS / POLLING)
              // =========================================================================
              Obx(() {
                if (!controller.isGenerating.value) return const SizedBox.shrink();
                final progress = controller.generationProgress.value;
                final isDone = progress >= 100;
                return Container(
                  margin: EdgeInsets.only(bottom: AppDimens.vSpacingMd),
                  padding: EdgeInsets.all(AppDimens.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                      color: isDone
                          ? AppColors.accentSuccess
                          : AppColors.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isDone ? AppColors.accentSuccess : AppColors.primary).withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 14.w,
                                  height: 14.w,
                                  child: isDone
                                      ? Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess, size: 14.sp)
                                      : const CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                        ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    controller.generationPhase.value.isNotEmpty
                                        ? controller.generationPhase.value
                                        : AppStrings.generatingOnGpu,
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: isDone ? AppColors.accentSuccess : AppColors.primary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            '$progress%',
                            style: AppTextStyles.captionBold.copyWith(
                              color: isDone ? AppColors.accentSuccess : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppDimens.vSpacingSm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        child: LinearProgressIndicator(
                          value: progress / 100.0,
                          backgroundColor: AppColors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDone ? AppColors.accentSuccess : AppColors.primary,
                          ),
                          minHeight: 6.h,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(Icons.lock_clock_outlined, size: 11.sp, color: AppColors.textMuted),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              'Studio locked • Diffusion process in progress',
                              style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),

              // =========================================================================
              // SECTION 7: PRIMARY GENERATION DISPATCH ACTION BUTTON
              // =========================================================================
              Obx(() {
                final isGen = controller.isGenerating.value;
                final isEnh = controller.isEnhancing.value;
                final isBusy = controller.isBusy;
                final progress = controller.generationProgress.value;

                String label;
                if (isGen) {
                  label = progress > 0
                      ? 'Generating on GPU ($progress%)...'
                      : AppStrings.generatingOnGpu;
                } else if (isEnh) {
                  label = 'Enhancing Prompt with AI...';
                } else {
                  label = '${AppStrings.btnGenerate} • ${controller.calculatedCreditCost} ${AppStrings.cr}';
                }

                return AppButton(
                  label: label,
                  onPressed: isBusy ? null : controller.generateVisual,
                  isLoading: isGen || isEnh,
                  icon: const Icon(Icons.auto_awesome, color: Colors.white),
                );
              }),
              SizedBox(height: AppDimens.vSpacingMd),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // HELPER MODAL SHEETS (ASPECT RATIO & REFERENCE PHOTO PICKER)
  // =========================================================================

  void _showAspectRatioSheet(BuildContext context, StudioController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
          border: Border.all(color: AppColors.border),
        ),
        padding: EdgeInsets.all(AppDimens.spacingLg),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.aspectRatioTitle, style: AppTextStyles.h3),
              SizedBox(height: AppDimens.vSpacingMd),
              Wrap(
                spacing: AppDimens.spacingSm,
                runSpacing: AppDimens.vSpacingSm,
                children: controller.aspectRatios.map((ratio) {
                  return Obx(() {
                    final isSel = controller.selectedAspectRatio.value == ratio;
                    return GestureDetector(
                      onTap: () {
                        controller.setAspectRatio(ratio);
                        Get.back();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(
                            color: isSel ? AppColors.primary : AppColors.border,
                            width: isSel ? 1.5 : 1.0,
                          ),
                        ),
                        child: Text(
                          ratio,
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            color: isSel ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
              ),
              SizedBox(height: AppDimens.vSpacingMd),
            ],
          ),
        ),
      ),
    );
  }

  void _showReferencePickerSheet(BuildContext context, StudioController controller) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(AppDimens.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
          border: Border.all(color: AppColors.border),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AppStrings.selectSampleReference, style: AppTextStyles.h3),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.white70),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.vSpacingSm),
              Text(
                'Lock facial bone structure and consistency across batches (Max 3).',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 6.h),
              Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: AppColors.accentSuccess, size: 12.sp),
                  SizedBox(width: 5.w),
                  Expanded(
                    child: Text(
                      'Zero-Retention Privacy: Uploaded photos are auto-purged from cloud immediately post-generation.',
                      style: AppTextStyles.captionXs.copyWith(color: AppColors.accentSuccess, fontSize: 9.5.sp),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.vSpacingLg),
              Row(
                children: [
                  _buildSampleSlot(
                    title: 'Front Angle',
                    url: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop',
                    controller: controller,
                  ),
                  SizedBox(width: AppDimens.spacingSm),
                  _buildSampleSlot(
                    title: '45° Angle',
                    url: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop',
                    controller: controller,
                  ),
                  SizedBox(width: AppDimens.spacingSm),
                  _buildSampleSlot(
                    title: 'Profile Angle',
                    url: 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=500&auto=format&fit=crop',
                    controller: controller,
                  ),
                ],
              ),
              SizedBox(height: AppDimens.vSpacingMd),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Get.back();
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.camera);
                        if (picked != null) {
                          controller.addReferencePhotoFile(File(picked.path));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                      ),
                      icon: Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: AppDimens.iconSm),
                      label: Text(
                        'Camera',
                        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                  SizedBox(width: AppDimens.spacingSm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Get.back();
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          controller.addReferencePhotoFile(File(picked.path));
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                      ),
                      icon: Icon(Icons.photo_library_outlined, color: AppColors.primary, size: AppDimens.iconSm),
                      label: Text(
                        'Gallery',
                        style: AppTextStyles.buttonSmall.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.vSpacingMd),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildSampleSlot({
    required String title,
    required String url,
    required StudioController controller,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          Get.back();
          controller.addReferenceImage(url);
        },
        child: Container(
          height: 100.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: AppColors.surfaceLight),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, AppColors.black.withValues(alpha: 0.8)],
                  ),
                ),
              ),
              Positioned(
                bottom: 6.h,
                left: 4.w,
                right: 4.w,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.captionXs.copyWith(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
