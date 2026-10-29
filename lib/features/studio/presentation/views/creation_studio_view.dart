import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:permission_handler/permission_handler.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/shared/utils/reference_image_uploader.dart';
import '../controllers/studio_controller.dart';
import '../widgets/studio_model_sheet.dart';
import '../widgets/studio_advanced_settings_sheet.dart';
import '../widgets/studio_prompt_engine_sheet.dart';
import '../../../../shared/widgets/app_button.dart';

class CreationStudioView extends StatelessWidget {
  const CreationStudioView({super.key});

  @override
  Widget build(BuildContext context) {
    final StudioController controller = Get.isRegistered<StudioController>()
        ? Get.find<StudioController>()
        : Get.put(StudioController());

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
              // SECTION 1: TOP HEADER & SURPRISE ME ACTION
              // =========================================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.studioTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.h1.copyWith(fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 2.h),
                        Row(
                          children: [
                            Container(
                              width: 6.r,
                              height: 6.r,
                              decoration: const BoxDecoration(
                                color: AppColors.accentSuccess,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: Text(
                                'Next-Gen Creation Studio',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.triggerSurpriseMe();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.casino_outlined, size: 14.sp, color: AppColors.primary),
                          SizedBox(width: 4.w),
                          Text(
                            'Surprise Me',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.primary,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppDimens.vSpacingMd),

              // =========================================================================
              // IN-STUDIO HERO RESULT CARD (SHOWN WHEN CREATION COMPLETES)
              // =========================================================================
              _buildResultHeroCard(context, controller),

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
                      // SECTION 2: VISUAL STYLE CAROUSEL (PINTEREST / PROMPTHERO TIER)
                      // =========================================================================
                      _buildVisualStyleCarousel(controller),
                      SizedBox(height: AppDimens.vSpacingMd),

                      // =========================================================================
                      // SECTION 3: HERO PROMPT CANVAS & VOICE ACTION
                      // =========================================================================
                      _buildPromptCanvas(context, controller),

                      // =========================================================================
                      // SECTION 3.5: AI ENHANCED STATUS BADGE
                      // =========================================================================
                      Obx(() {
                        if (!controller.isPromptEnhanced) return const SizedBox.shrink();
                        return Container(
                          margin: EdgeInsets.only(top: AppDimens.vSpacingSm),
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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

                      // Image Edit Mode Status Pill
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
                      // SECTION 4: REFERENCE PHOTO INPUT SLOT & PRIVACY NOTICE
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
                                            fontWeight: FontWeight.bold,
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

                        return Container(
                          margin: EdgeInsets.only(top: AppDimens.vSpacingSm),
                          padding: EdgeInsets.all(AppDimens.spacingSm),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Obx(() {
                                    final currentCount = controller.referenceImages.length;
                                    return Row(
                                      children: [
                                        Icon(Icons.photo_library_outlined, size: 13.sp, color: AppColors.textPrimary),
                                        SizedBox(width: 4.w),
                                        Text(
                                          'Active Reference Photos ($currentCount/3)',
                                          style: AppTextStyles.captionBold.copyWith(
                                            color: AppColors.textPrimary,
                                            fontSize: 11.sp,
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
                      // SECTION 4.5: GEOMETRIC ASPECT RATIO BAR (PHOTO STUDIO TIER)
                      // =========================================================================
                      _buildVisualAspectRatioBar(controller),
                      SizedBox(height: AppDimens.vSpacingMd),

                      // =========================================================================
                      // SECTION 5: MODEL & ADVANCED PARAMETERS BAR
                      // =========================================================================
                      _buildQuickParametersBar(context, controller),
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
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    border: Border.all(
                      color: isDone ? AppColors.accentSuccess : AppColors.primary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        blurRadius: 10,
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
                                  width: 16.sp,
                                  height: 16.sp,
                                  child: isDone
                                      ? const Icon(Icons.check_circle, color: AppColors.accentSuccess, size: 16)
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
                final isBusy = controller.isBusy;
                final progress = controller.generationProgress.value;

                final String label = isGen
                    ? (progress > 0
                        ? 'Generating on GPU ($progress%)...'
                        : AppStrings.generatingOnGpu)
                    : '${AppStrings.btnGenerate} • ${controller.calculatedCreditCost} ${AppStrings.cr}';

                return AppButton(
                  label: label,
                  onPressed: isBusy ? null : controller.generateVisual,
                  isLoading: isGen,
                  icon: const Icon(Icons.auto_awesome, color: AppColors.surface),
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
  // HELPER WIDGETS (HIGH-END AESTHETIC CARDS & GEOMETRY STRIP)
  // =========================================================================

  IconData _resolveStyleIcon(String? iconName) {
    switch (iconName) {
      case 'camera':
        return Icons.camera_alt_rounded;
      case '3d':
        return Icons.view_in_ar_rounded;
      case 'anime':
        return Icons.auto_awesome_rounded;
      case 'neon':
        return Icons.bolt_rounded;
      case 'film':
        return Icons.movie_filter_rounded;
      case 'paint':
        return Icons.palette_rounded;
      default:
        return Icons.palette_outlined;
    }
  }

  String _formatAspectRatioLabel(String ratio) {
    switch (ratio) {
      case '1:1':
        return 'Square (1:1)';
      case '9:16':
        return 'Story (9:16)';
      case '4:5':
        return 'Portrait (4:5)';
      case '16:9':
        return 'Cinema (16:9)';
      default:
        return ratio;
    }
  }

  /// Visual 1-Tap Style Carousel for zero-typing aesthetic selection (Pinterest / PromptHero tier)
  Widget _buildVisualStyleCarousel(StudioController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.style_outlined, size: 15.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      'Artistic Style Preset',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Flexible(
              child: Obx(() => Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
                child: Text(
                  controller.selectedStylePreset.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.captionXs.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          height: (112.h).clamp(110.0, 140.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.visualStyles.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final style = controller.visualStyles[index];
              return Obx(() {
                final isSelected = controller.selectedStylePreset.value == style['name'];
                final startColor = Color(style['gradientStart'] as int? ?? 0xFF1E2022);
                final endColor = Color(style['gradientEnd'] as int? ?? 0xFF3B3E42);

                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.selectVisualStyle(style);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 124.w,
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [startColor, endColor],
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.white.withValues(alpha: 0.15),
                        width: isSelected ? 2.2 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: endColor.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 28.r,
                              height: 28.r,
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.white.withValues(alpha: 0.25)),
                              ),
                              child: Center(
                                child: Icon(
                                  _resolveStyleIcon(style['iconName'] as String?),
                                  color: AppColors.white,
                                  size: 14.sp,
                                ),
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Flexible(
                              child: isSelected
                                  ? Container(
                                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.white,
                                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check, size: 9.sp, color: AppColors.primary),
                                          SizedBox(width: 2.w),
                                          Flexible(
                                            child: Text(
                                              'Active',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 8.5.sp,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.black.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                                      ),
                                      child: Text(
                                        style['category'] as String? ?? 'Style',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: AppColors.white70,
                                          fontSize: 8.5.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              style['name'] as String,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 1.h),
                            Text(
                              style['subtitle'] as String? ?? '',
                              style: TextStyle(
                                color: AppColors.white.withValues(alpha: 0.75),
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }

  /// Prompt Canvas Card with voice dictation & polish action
  Widget _buildPromptCanvas(BuildContext context, StudioController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppDimens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_note_rounded, size: 16.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text(
                    'Prompt Canvas',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Obx(() => Text(
                '${controller.promptLength.value} / 1000',
                style: AppTextStyles.captionXs.copyWith(
                  color: controller.promptLength.value > 900
                      ? AppColors.accentWarning
                      : AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              )),
            ],
          ),
          SizedBox(height: 8.h),
          Obx(() => TextField(
            controller: controller.promptController,
            enabled: !controller.isBusy,
            maxLines: 3,
            maxLength: 1000,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Describe anything you want to create...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          )),
          Divider(color: AppColors.border.withValues(alpha: 0.5), height: 16.h),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6.w,
            runSpacing: 8.h,
            children: [
              // Left: Reference Photo (Voice input commented out for now per user instruction)
              /*
              GestureDetector(
                onTap: () => _handleVoiceInput(context, controller),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mic_rounded, color: AppColors.primary, size: 15.sp),
                      SizedBox(width: 4.w),
                      Text(
                        'Voice',
                        style: AppTextStyles.captionBold.copyWith(
                          color: AppColors.primary,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              */
              GestureDetector(
                onTap: () => _showReferencePickerSheet(context, controller),
                child: Obx(() {
                  final hasRef = controller.referenceImages.isNotEmpty;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: hasRef ? AppColors.accentSuccess.withValues(alpha: 0.12) : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      border: Border.all(color: hasRef ? AppColors.accentSuccess : AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasRef ? Icons.check_circle_rounded : Icons.add_photo_alternate_outlined,
                          color: hasRef ? AppColors.accentSuccess : AppColors.textSecondary,
                          size: 14.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          hasRef ? 'Photo (${controller.referenceImages.length})' : '+ Photo',
                          style: AppTextStyles.captionBold.copyWith(
                            color: hasRef ? AppColors.accentSuccess : AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // Right: Clear Button + Copilot + AI Engine Selector + Polish Button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(() {
                    if (controller.promptLength.value == 0) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => controller.promptController.clear(),
                      child: Padding(
                        padding: EdgeInsets.only(right: 6.w),
                        child: Icon(Icons.cancel_rounded, color: AppColors.textMuted, size: 16.sp),
                      ),
                    );
                  }),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.copilotAccent, size: 16.sp),
                    tooltip: AppStrings.btnCopilot,
                    onPressed: controller.openPromptChatCopilot,
                  ),
                  IconButton(
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                    icon: Icon(Icons.document_scanner_outlined, color: AppColors.primary, size: 16.sp),
                    tooltip: 'Scan Photo to Prompt (Vision)',
                    onPressed: () => _handleVisionScan(context, controller),
                  ),
                  SizedBox(width: 4.w),
                  // AI Engine Selector Chip (Gemini, Groq, Claude, GPT)
                  Obx(() {
                    final currentId = controller.selectedPromptEngine.value;
                    final engine = controller.availablePromptEngines.firstWhere(
                      (e) => e['id'] == currentId,
                      orElse: () => controller.availablePromptEngines.first,
                    );
                    return GestureDetector(
                      onTap: () => StudioPromptEngineSheet.show(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 5.h),
                        margin: EdgeInsets.only(right: 6.w),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(engine['icon'] ?? '♊', style: TextStyle(fontSize: 11.sp)),
                            SizedBox(width: 3.w),
                            Text(
                              engine['id'] == 'gemini'
                                  ? 'Gemini'
                                  : engine['id'] == 'groq'
                                      ? 'Groq'
                                      : engine['id'] == 'claude'
                                          ? 'Claude'
                                          : 'GPT-4o',
                              style: AppTextStyles.captionXs.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Icon(Icons.arrow_drop_down_rounded, size: 14.sp, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    );
                  }),
                  Obx(() {
                    final isEnhancing = controller.isEnhancing.value;
                    final hasPrompt = controller.promptLength.value > 0;
                    return GestureDetector(
                      onTap: isEnhancing ? null : controller.enhancePrompt,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: hasPrompt ? AppColors.primary : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(
                            color: hasPrompt ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isEnhancing)
                              SizedBox(
                                width: 12.sp,
                                height: 12.sp,
                                child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.surface),
                              )
                            else
                              Icon(
                                Icons.auto_awesome_rounded,
                                color: hasPrompt ? AppColors.surface : AppColors.textMuted,
                                size: 13.sp,
                              ),
                            SizedBox(width: 4.w),
                            Text(
                              isEnhancing ? 'Polishing...' : 'Polish ✨',
                              style: AppTextStyles.captionBold.copyWith(
                                color: hasPrompt ? AppColors.surface : AppColors.textMuted,
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
            ],
          ),
        ],
      ),
    );
  }

  /// Geometric Aspect Ratio Selector Bar (Photo Studio Tier)
  Widget _buildVisualAspectRatioBar(StudioController controller) {
    final ratios = const [
      {
        'id': '1:1',
        'name': 'Square',
        'sub': '1:1 Post',
        'width': 20.0,
        'height': 20.0,
      },
      {
        'id': '9:16',
        'name': 'Story',
        'sub': '9:16 Reels',
        'width': 13.0,
        'height': 23.0,
      },
      {
        'id': '4:5',
        'name': 'Portrait',
        'sub': '4:5 Feed',
        'width': 16.0,
        'height': 20.0,
      },
      {
        'id': '16:9',
        'name': 'Cinema',
        'sub': '16:9 Wide',
        'width': 24.0,
        'height': 13.0,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.crop_outlined, size: 15.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      'Aspect Ratio & Frame',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 6.w),
            Obx(() => Text(
              _formatAspectRatioLabel(controller.selectedAspectRatio.value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.captionXs.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            )),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: ratios.map((r) {
            final id = r['id'] as String;
            final name = r['name'] as String;
            final sub = r['sub'] as String;
            final w = r['width'] as double;
            final h = r['height'] as double;

            return Expanded(
              child: Obx(() {
                final isSelected = controller.selectedAspectRatio.value == id;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    controller.setAspectRatio(id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 24.h,
                          child: Center(
                            child: Container(
                              width: w.w,
                              height: h.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2.r),
                                border: Border.all(
                                  color: isSelected ? AppColors.surface : AppColors.textSecondary,
                                  width: 1.5,
                                ),
                                color: isSelected
                                    ? AppColors.surface.withValues(alpha: 0.25)
                                    : AppColors.surfaceLight,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          name,
                          style: TextStyle(
                            color: isSelected ? AppColors.surface : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 10.5.sp,
                          ),
                        ),
                        Text(
                          sub,
                          style: TextStyle(
                            color: isSelected ? AppColors.surface.withValues(alpha: 0.75) : AppColors.textMuted,
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Model and Advanced Parameter Bar
  Widget _buildQuickParametersBar(BuildContext context, StudioController controller) {
    return SizedBox(
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
                    Icon(Icons.memory_rounded, size: 14.sp, color: AppColors.primary),
                    SizedBox(width: 5.w),
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
                  Icon(Icons.high_quality_rounded, color: AppColors.textSecondary, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    controller.selectedResolution.value,
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            )),
          ),

          // Advanced Settings Pill
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
                  Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'More Settings',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// In-Studio Hero Result Reveal Card (Celebratory result shown without tab jump)
  Widget _buildResultHeroCard(BuildContext context, StudioController controller) {
    return Obx(() {
      if (!controller.showResultHero.value || controller.lastGeneratedImageUrl.value == null) {
        return const SizedBox.shrink();
      }
      final imageUrl = controller.lastGeneratedImageUrl.value!;

      return Container(
        margin: EdgeInsets.only(bottom: AppDimens.vSpacingMd),
        padding: EdgeInsets.all(AppDimens.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentSuccess.withValues(alpha: 0.12),
              blurRadius: 16,
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
                Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess, size: 18.sp),
                    SizedBox(width: 6.w),
                    Text(
                      'Creation Complete! ✨',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: controller.closeResultHero,
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: const BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close, color: AppColors.textMuted, size: 14.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),

            // High-Res Image Preview
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 40),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Action Buttons Bar
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Get.snackbar(
                        'Saved to Photos 📥',
                        'Artwork saved to your device in original 2K resolution.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.surface,
                        colorText: AppColors.accentSuccess,
                        duration: const Duration(seconds: 3),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                    ),
                    icon: Icon(Icons.download_rounded, size: 16.sp, color: AppColors.surface),
                    label: Text(
                      'Save HD',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.surface),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final shellCtrl = Get.find<ShellController>();
                      shellCtrl.switchTab(3); // View in Library
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                    ),
                    icon: Icon(Icons.photo_library_outlined, size: 16.sp, color: AppColors.primary),
                    label: Text(
                      'Library',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: controller.closeResultHero,
                  tooltip: 'Create Another',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                  ),
                  icon: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 18.sp),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  // =========================================================================
  // VOICE DICTATION & PERMISSION HANDLING (PROMPTHERO TIER)
  // =========================================================================

  /*
  Future<void> _handleVoiceInput(BuildContext context, StudioController controller) async {
    HapticFeedback.lightImpact();
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      if (context.mounted) _showVoiceListeningSheet(context, controller);
      return;
    }

    if (status.isDenied) {
      final requested = await Permission.microphone.request();
      if (requested.isGranted) {
        if (context.mounted) _showVoiceListeningSheet(context, controller);
      } else {
        if (!context.mounted) return;
        Get.snackbar(
          'Microphone Permission Needed 🎙️',
          'Please allow microphone access to speak prompt ideas in your language.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.accentWarning,
          duration: const Duration(seconds: 4),
        );
      }
      return;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return;
      _showPermissionSettingsDialog(context);
    }
  }

  void _showPermissionSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
        title: Row(
          children: [
            Icon(Icons.mic_off_rounded, color: AppColors.accentWarning, size: 22.sp),
            SizedBox(width: 8.w),
            Text('Microphone Blocked', style: AppTextStyles.h3),
          ],
        ),
        content: Text(
          'Microphone permission was permanently disabled for CraftAI Studio. Please enable it in Device Settings to dictate prompt ideas.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
            ),
            child: Text('Open Settings', style: AppTextStyles.captionBold.copyWith(color: AppColors.surface)),
          ),
        ],
      ),
    );
  }

  void _showVoiceListeningSheet(BuildContext context, StudioController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
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
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mic_rounded, color: AppColors.primary, size: 20.sp),
                      SizedBox(width: 8.w),
                      Text('Voice Dictation', style: AppTextStyles.h3),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18.sp),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                'Speak your idea in Hindi or English, or tap a trending idea below:',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 20.h),

              // Animated Pulsing Listening Orb
              SizedBox(
                height: 90.r,
                width: 90.r,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.9, end: 1.15),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeInOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4), width: 2),
                        ),
                        child: Center(
                          child: Container(
                            width: 58.r,
                            height: 58.r,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.mic_rounded, color: AppColors.surface, size: 28.sp),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                'Listening for your voice...',
                style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
              ),
              SizedBox(height: 20.h),

              // Curated Prompt Suggestions (Pinterest / PromptHero tier)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Or Tap a Trending Prompt Idea:',
                  style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                ),
              ),
              SizedBox(height: 10.h),
              Column(
                children: [
                  _buildCuratedVoiceCard(
                    controller,
                    title: 'Studio Portrait',
                    prompt: 'Cinematic studio portrait with soft Rembrandt lighting and 85mm lens',
                    icon: Icons.camera_alt_outlined,
                    style: 'Realistic Photo',
                  ),
                  SizedBox(height: 8.h),
                  _buildCuratedVoiceCard(
                    controller,
                    title: 'Cyberpunk City',
                    prompt: 'Futuristic rainy Tokyo street with neon holographic signs and flying cars',
                    icon: Icons.electric_bolt_outlined,
                    style: 'Cyberpunk Neon',
                  ),
                  SizedBox(height: 8.h),
                  _buildCuratedVoiceCard(
                    controller,
                    title: '3D Pixar Character',
                    prompt: 'Cute 3D claymation animated chef cooking glowing pancakes in cozy kitchen',
                    icon: Icons.view_in_ar_outlined,
                    style: '3D Cartoon',
                  ),
                ],
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCuratedVoiceCard(
    StudioController controller, {
    required String title,
    required String prompt,
    required IconData icon,
    required String style,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        controller.promptController.text = prompt;
        final targetStyle = controller.visualStyles.firstWhere(
          (s) => s['name'] == style,
          orElse: () => controller.visualStyles.first,
        );
        controller.selectVisualStyle(targetStyle);
        Get.back();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(7.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(icon, size: 16.sp, color: AppColors.primary),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                  ),
                  Text(
                    prompt,
                    style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12.sp, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
  */

  // =========================================================================
  // REFERENCE PHOTO PICKER SHEET
  // =========================================================================

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
                  Icon(Icons.shield_outlined, color: AppColors.accentSuccess, size: 12.sp),
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

  Future<void> _handleVisionScan(BuildContext context, StudioController controller) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920, maxHeight: 1920);
    if (xfile != null) {
      Get.snackbar(
        'Analyzing Photo 🔍',
        'Gemini 2.5 Flash is reverse-engineering style & aesthetics...',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        duration: const Duration(seconds: 2),
      );
      final upRes = await ReferenceImageUploader.uploadReferenceImage(File(xfile.path));
      if (upRes.url != null) {
        await controller.scanPhotoToPrompt(upRes.url!);
      }
    }
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
