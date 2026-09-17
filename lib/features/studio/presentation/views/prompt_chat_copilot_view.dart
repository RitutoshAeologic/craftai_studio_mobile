import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import '../../domain/models/copilot_message_model.dart';
import '../controllers/prompt_chat_copilot_controller.dart';

class PromptChatCopilotView extends StatelessWidget {
  const PromptChatCopilotView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.isRegistered<PromptChatCopilotController>()
        ? Get.find<PromptChatCopilotController>()
        : Get.put(PromptChatCopilotController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppDimens.spacingSm),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              ),
              child: Icon(Icons.auto_awesome, color: Colors.white, size: AppDimens.iconSm),
            ),
            SizedBox(width: AppDimens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppStrings.copilotTitle,
                    style: AppTextStyles.h2.copyWith(color: AppColors.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    AppStrings.copilotSubtitle,
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
              margin: EdgeInsets.only(right: AppDimens.spacingLg),
              padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingSm, vertical: AppDimens.vSpacingXs),
              decoration: BoxDecoration(
                color: controller.turnCount.value >= 4
                    ? AppColors.orangeAccent.withValues(alpha: 0.2)
                    : AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                border: Border.all(
                  color: controller.turnCount.value >= 4
                      ? AppColors.orangeAccent
                      : AppColors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Center(
                child: Text(
                  '${controller.turnCount.value}/5 ${AppStrings.refinesSuffix}',
                  style: AppTextStyles.captionBold.copyWith(
                    color: controller.turnCount.value >= 4
                        ? AppColors.orangeAccent
                        : AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Active Image & Prompt Context Card
            _buildActiveContextCard(controller),

            // AI Prompt Engine Selector Bar
            _buildAiEngineBar(controller),

            // 1-Click Action Chips Bar
            _buildQuickActionChips(controller),

            // Chat Messages List
            Expanded(
              child: Obx(
                () => ListView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppDimens.spacingLg,
                    vertical: AppDimens.vSpacingLg,
                  ),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) {
                    final msg = controller.messages[index];
                    return _buildMessageBubble(msg);
                  },
                ),
              ),
            ),

            // Smart Suggestion Pills
            _buildSuggestionPills(controller),

            // Bottom Input & Generate Bar
            _buildBottomBar(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveContextCard(PromptChatCopilotController controller) {
    return Obx(() {
      final prompt = controller.activeBasePrompt.value;
      final imageUrl = controller.activeImageUrl.value;
      if (prompt.isEmpty && imageUrl.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg, vertical: AppDimens.vSpacingMd),
        padding: EdgeInsets.all(AppDimens.spacingMd),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  width: 48.w,
                  height: 48.w,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 48.w,
                    height: 48.w,
                    color: AppColors.surfaceLight,
                    child: Icon(Icons.broken_image, color: AppColors.textMuted, size: AppDimens.iconSm),
                  ),
                ),
              ),
            if (imageUrl.isNotEmpty) SizedBox(width: AppDimens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.activeBasePromptTitle,
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                  ),
                  SizedBox(height: AppDimens.vSpacingXxs),
                  Text(
                    prompt.isNotEmpty ? prompt : AppStrings.noPromptSet,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAiEngineBar(PromptChatCopilotController controller) {
    final engines = const [
      {'id': 'groq', 'label': '⚡ Groq LPU', 'badge': '<0.8s'},
      {'id': 'gemini', 'label': '♊ Gemini 2.5', 'badge': 'Creative'},
      {'id': 'claude', 'label': '🧠 Claude 3.5', 'badge': 'Photoreal'},
      {'id': 'gpt4', 'label': '🤖 GPT-4o', 'badge': 'Balanced'},
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg, vertical: 4.h),
      height: 38.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: engines.length,
        separatorBuilder: (_, __) => SizedBox(width: AppDimens.spacingSm),
        itemBuilder: (context, index) {
          final e = engines[index];
          return Obx(() {
            final isSel = controller.selectedAiEngine.value == e['id'];
            return GestureDetector(
              onTap: () => controller.setAiEngine(e['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.copilotPurple.withValues(alpha: 0.25) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                  border: Border.all(
                    color: isSel ? AppColors.copilotAccent : AppColors.border,
                    width: isSel ? 1.4 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      e['label']!,
                      style: AppTextStyles.captionBold.copyWith(
                        color: isSel ? AppColors.copilotAccent : AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      e['badge']!,
                      style: AppTextStyles.captionXs.copyWith(
                        color: isSel ? AppColors.white : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          });
        },
      ),
    );
  }

  Widget _buildQuickActionChips(PromptChatCopilotController controller) {
    return Container(
      height: 38.h,
      margin: EdgeInsets.only(top: AppDimens.vSpacingXs, bottom: AppDimens.vSpacingSm),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
        scrollDirection: Axis.horizontal,
        itemCount: controller.quickActionChips.length,
        separatorBuilder: (_, __) => SizedBox(width: AppDimens.spacingSm),
        itemBuilder: (context, index) {
          final chip = controller.quickActionChips[index];
          return ActionChip(
            backgroundColor: AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              side: const BorderSide(color: AppColors.border),
            ),
            label: Text(
              chip['label']!,
              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
            ),
            onPressed: () => controller.applyQuickTool(
              chip['action']!,
              chip['preset']!,
              chip['label']!,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(CopilotMessage msg) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: AppDimens.vSpacingLg),
        constraints: BoxConstraints(maxWidth: 0.82.sw),
        padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg, vertical: 10.h),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimens.radiusXl),
            topRight: Radius.circular(AppDimens.radiusXl),
            bottomLeft: isUser ? Radius.circular(AppDimens.radiusXl) : Radius.zero,
            bottomRight: isUser ? Radius.zero : Radius.circular(AppDimens.radiusXl),
          ),
          border: Border.all(
            color: isUser
                ? AppColors.primary
                : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: AppTextStyles.bodySmall.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
            if (msg.addedTags.isNotEmpty || msg.removedTags.isNotEmpty) ...[
              SizedBox(height: AppDimens.vSpacingSm),
              Wrap(
                spacing: AppDimens.spacingXs,
                runSpacing: AppDimens.vSpacingXs,
                children: [
                  ...msg.addedTags.map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                        border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '+$tag',
                        style: AppTextStyles.captionXs.copyWith(color: AppColors.accentSuccess),
                      ),
                    ),
                  ),
                  ...msg.removedTags.map(
                    (tag) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentError.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                        border: Border.all(color: AppColors.accentError.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '-$tag',
                        style: AppTextStyles.captionXs.copyWith(color: AppColors.accentError),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionPills(PromptChatCopilotController controller) {
    return Obx(() {
      if (controller.suggestionChips.isEmpty) return const SizedBox.shrink();
      return Container(
        height: 32.h,
        margin: EdgeInsets.only(bottom: AppDimens.vSpacingSm),
        child: ListView.separated(
          padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg),
          scrollDirection: Axis.horizontal,
          itemCount: controller.suggestionChips.length,
          separatorBuilder: (_, __) => SizedBox(width: AppDimens.spacingSm),
          itemBuilder: (context, index) {
            final suggestion = controller.suggestionChips[index];
            return GestureDetector(
              onTap: () => controller.sendInstruction(suggestion),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    suggestion,
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildBottomBar(PromptChatCopilotController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingLg, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.w)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppDimens.spacingMd),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimens.radiusXl),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: controller.inputController,
                    style: AppTextStyles.bodyMedium,
                    decoration: InputDecoration(
                      hintText: AppStrings.copilotInputHint,
                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                      border: InputBorder.none,
                    ),
                    onSubmitted: controller.sendInstruction,
                  ),
                ),
              ),
              SizedBox(width: AppDimens.spacingSm),
              Obx(
                () => IconButton(
                  icon: controller.isLoading.value
                      ? SizedBox(
                          width: 18.w,
                          height: 18.w,
                          child: const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                        )
                      : Icon(Icons.send, color: AppColors.primary, size: AppDimens.iconLg),
                  onPressed: controller.isLoading.value
                      ? null
                      : () => controller.sendInstruction(controller.inputController.text),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.vSpacingSm),
          SizedBox(
            width: double.infinity,
            height: 42.h,
            child: ElevatedButton.icon(
              onPressed: controller.syncToStudioAndGenerate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusLg)),
              ),
              icon: Icon(Icons.auto_awesome, color: Colors.white, size: AppDimens.iconSm),
              label: Text(
                AppStrings.btnGenerateWithRefined,
                style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
