import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/shared/widgets/before_after_slider.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import '../controllers/remix_chat_controller.dart';
import '../domain/models/remix_message_model.dart';

/// [RemixChatView] delivers a dedicated, conversational image remixing experience.
/// Perfectly conforms to rules.md §5 responsive standards (390x844dp ScreenUtil)
/// with zero raw hex colors, resilient keyboard adaptation, and interactive Before/After comparison.
class RemixChatView extends StatefulWidget {
  const RemixChatView({super.key});

  @override
  State<RemixChatView> createState() => _RemixChatViewState();
}

class _RemixChatViewState extends State<RemixChatView> {
  late final RemixChatController controller;

  @override
  void initState() {
    super.initState();
    // Guarantee fresh controller instance per session to prevent cross-artwork state collision
    if (Get.isRegistered<RemixChatController>()) {
      Get.delete<RemixChatController>();
    }
    controller = Get.put(RemixChatController());
  }

  @override
  void dispose() {
    if (Get.isRegistered<RemixChatController>()) {
      Get.delete<RemixChatController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shellCtrl = Get.isRegistered<ShellController>()
        ? Get.find<ShellController>()
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppDimens.spacingSm),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.purpleAccent, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(Icons.shuffle_rounded, color: Colors.white, size: AppDimens.iconSm),
            ),
            SizedBox(width: AppDimens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Remix Lab',
                    style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Conversational Prompt Refinement',
                    style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Obx(
            () => Container(
              margin: EdgeInsets.only(right: AppDimens.spacingMd),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: controller.turnCount.value >= 4
                    ? AppColors.orangeAccent.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                border: Border.all(
                  color: controller.turnCount.value >= 4
                      ? AppColors.orangeAccent
                      : AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '${controller.turnCount.value}/5 Turns',
                  style: AppTextStyles.captionBold.copyWith(
                    color: controller.turnCount.value >= 4
                        ? AppColors.orangeAccent
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
          if (shellCtrl != null)
            Obx(
              () => Container(
                margin: EdgeInsets.only(right: AppDimens.spacingLg),
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    '${shellCtrl.userCredits.value.toInt()} Cr',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.accentWarning),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── 1. Sticky Visual Anchor & Style Weight Strip ──────────────
            _buildStickyAnchorBar(controller),

            // ── 2. In-Flight Progress Indicator (If Generating) ───────────
            Obx(() {
              if (!controller.isGenerating.value) return const SizedBox.shrink();
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          controller.generationPhase.value,
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.primary),
                        ),
                        Text(
                          '${controller.generationProgress.value}%',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    LinearProgressIndicator(
                      value: controller.generationProgress.value / 100.0,
                      backgroundColor: AppColors.surfaceLight,
                      color: AppColors.primary,
                      minHeight: 3.h,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ],
                ),
              );
            }),

            // ── 3. Chat Message Stream ────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                behavior: HitTestBehavior.opaque,
                child: Obx(
                  () => ListView.builder(
                    controller: controller.scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimens.spacingLg,
                      vertical: AppDimens.vSpacingMd,
                    ),
                    itemCount: controller.messages.length,
                    itemBuilder: (context, index) {
                      final msg = controller.messages[index];
                      return _buildMessageBubble(context, controller, msg);
                    },
                  ),
                ),
              ),
            ),

            // ── 4. Quick Aesthetic Modifier Chips ─────────────────────────
            _buildQuickModifiersBar(controller),

            // ── 5. Input Field Bar with Live Counter ──────────────────────
            _buildInputControlBar(controller),

            // ── 6. Fixed Bottom Action CTA: Generate Remix ────────────────
            _buildGenerateCta(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyAnchorBar(RemixChatController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.w)),
      ),
      child: Row(
        children: [
          // Anchor Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            child: Container(
              width: 44.w,
              height: 44.w,
              color: AppColors.surfaceLight,
              child: Obx(() {
                final url = controller.anchorImageUrl.value;
                if (url.isEmpty) {
                  return Icon(Icons.image_outlined, color: AppColors.textMuted, size: 20.sp);
                }
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Icon(Icons.broken_image, size: 18.sp, color: AppColors.textMuted),
                );
              }),
            ),
          ),
          SizedBox(width: 10.w),

          // Details & Style Intensity Selector
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 12.sp, color: AppColors.purpleAccent),
                        SizedBox(width: 4.w),
                        Text(
                          'Composition Anchor Locked',
                          style: AppTextStyles.captionXs.copyWith(
                            color: AppColors.purpleAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Obx(
                      () => Text(
                        '${(controller.styleWeight.value * 100).toInt()}% Intensity',
                        style: AppTextStyles.captionXs.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),

                // Segmented Intensity Selector Pills
                Obx(() {
                  final currentWeight = controller.styleWeight.value;
                  return Row(
                    children: [
                      _buildIntensityPill(controller, 'Subtle (30%)', 0.30, currentWeight == 0.30),
                      SizedBox(width: 6.w),
                      _buildIntensityPill(controller, 'Balanced (60%)', 0.60, currentWeight == 0.60),
                      SizedBox(width: 6.w),
                      _buildIntensityPill(controller, 'Bold (90%)', 0.90, currentWeight == 0.90),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntensityPill(
    RemixChatController controller,
    String label,
    double weight,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setStyleWeight(weight),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 3.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(4.r),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.captionXs.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 9.sp,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    RemixChatController controller,
    RemixMessageModel msg,
  ) {
    final isUser = msg.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimens.vSpacingMd),
        constraints: BoxConstraints(maxWidth: 0.85.sw),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.r),
                  topRight: Radius.circular(16.r),
                  bottomLeft: Radius.circular(isUser ? 16.r : 4.r),
                  bottomRight: Radius.circular(isUser ? 4.r : 16.r),
                ),
                border: Border.all(
                  color: isUser ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isUser ? Colors.white : AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),

                  // Diff Tags (if present)
                  if (!isUser && msg.diffAdded.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children: msg.diffAdded.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentSuccess.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4.r),
                            border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '+ $tag',
                            style: AppTextStyles.captionXs.copyWith(
                              color: AppColors.accentSuccess,
                              fontWeight: FontWeight.bold,
                              fontSize: 10.sp,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  // Embedded Before/After Slider if image was generated in this turn
                  if (msg.generatedImageUrl != null && msg.generatedImageUrl!.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    BeforeAfterSlider(
                      beforeImageUrl: controller.anchorImageUrl.value,
                      afterImageUrl: msg.generatedImageUrl!,
                      height: 240,
                    ),
                  ],
                ],
              ),
            ),

            // Metadata footer (Role • Model • Latency)
            Padding(
              padding: EdgeInsets.only(top: 4.h, left: 4.w, right: 4.w),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.isOptimistic)
                    Padding(
                      padding: EdgeInsets.only(right: 4.w),
                      child: SizedBox(
                        width: 10.w,
                        height: 10.w,
                        child: const CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                      ),
                    ),
                  Text(
                    isUser
                        ? (msg.isOptimistic ? 'Sending...' : 'You')
                        : 'Remix Assistant ${msg.latencyMs != null ? '• ${msg.latencyMs}ms' : ''}',
                    style: AppTextStyles.captionXs.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10.sp,
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

  Widget _buildQuickModifiersBar(RemixChatController controller) {
    return Container(
      height: 36.h,
      margin: EdgeInsets.only(bottom: 6.h),
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
          itemCount: controller.suggestedChips.length,
          separatorBuilder: (_, __) => SizedBox(width: 6.w),
          itemBuilder: (context, index) {
            final chip = controller.suggestedChips[index];
            return ActionChip(
              label: Text(chip),
              labelStyle: AppTextStyles.captionXs.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                side: const BorderSide(color: AppColors.border),
              ),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 0),
              onPressed: () => controller.addModifierTag(chip),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputControlBar(RemixChatController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.w)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller.inputController,
                  maxLines: 2,
                  minLines: 1,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Describe style tweaks to the anchor image...',
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                  ),
                  onSubmitted: (text) => controller.sendInstruction(text),
                ),
              ),
              SizedBox(width: 8.w),

              // Send Button
              Obx(() {
                final isBusy = controller.isSending.value || controller.isGenerating.value;
                final isLimitReached = controller.turnCount.value >= 5;
                final isOverLimit = controller.promptLength.value > 500;
                final isBlank = controller.inputController.text.trim().isEmpty;
                final isSendDisabled = isBusy || isLimitReached || isOverLimit || isBlank;
                return IconButton(
                  onPressed: isSendDisabled
                      ? null
                      : () => controller.sendInstruction(controller.inputController.text),
                  icon: isBusy
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : Icon(
                          Icons.arrow_upward_rounded,
                          color: isSendDisabled ? AppColors.textMuted : AppColors.primary,
                          size: 22.sp,
                        ),
                  style: IconButton.styleFrom(
                    backgroundColor: isSendDisabled ? AppColors.surfaceLight : AppColors.primary.withValues(alpha: 0.15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                  ),
                );
              }),
            ],
          ),

          // Live Turn & Character Counter (rules.md §6)
          Obx(() {
            final len = controller.promptLength.value;
            final isOverLimit = len > 500;
            final isNearLimit = len >= 450 && !isOverLimit;
            final turn = controller.turnCount.value;
            return Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    turn >= 5 ? 'Refinement complete (5/5 turns)' : 'Turn $turn/5',
                    style: AppTextStyles.captionXs.copyWith(
                      color: turn >= 5 ? AppColors.orangeAccent : AppColors.textMuted,
                      fontSize: 10.sp,
                      fontWeight: turn >= 5 ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  Text(
                    '$len/500',
                    style: AppTextStyles.captionXs.copyWith(
                      color: isOverLimit
                          ? AppColors.accentError
                          : isNearLimit
                              ? AppColors.orangeAccent
                              : AppColors.textMuted,
                      fontSize: 10.sp,
                      fontWeight: isOverLimit ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGenerateCta(RemixChatController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
      color: AppColors.surface,
      child: Obx(() {
        final isBusy = controller.isGenerating.value || controller.isSending.value;
        return SizedBox(
          width: double.infinity,
          height: 44.h,
          child: ElevatedButton.icon(
            onPressed: isBusy ? null : () => controller.generateRemix(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
            ),
            icon: isBusy
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Icon(Icons.auto_awesome, size: 16.sp, color: Colors.white),
            label: Text(
              isBusy
                  ? (controller.isGenerating.value ? 'Diffusing Latents...' : 'Refining Recipe...')
                  : '⚡ Generate Remix (1 Credit)',
              style: AppTextStyles.bodyMediumBold.copyWith(color: Colors.white),
            ),
          ),
        );
      }),
    );
  }
}
