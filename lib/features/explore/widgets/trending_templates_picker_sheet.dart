import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import '../views/trending_templates_view.dart';
import 'template_photo_remix_bottom_sheet.dart';

class TrendingTemplatesPickerSheet extends StatelessWidget {
  const TrendingTemplatesPickerSheet({super.key});

  static void show(BuildContext context) {
    Get.to(
      () => const TrendingTemplatesView(),
      transition: Transition.cupertino,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExploreController exploreCtrl = Get.isRegistered<ExploreController>()
        ? Get.find<ExploreController>()
        : Get.put(ExploreController());

    if (exploreCtrl.cards.isEmpty && !exploreCtrl.isInitialLoading.value) {
      exploreCtrl.fetchExploreCards(isRefresh: true);
    }

    return Container(
      constraints: BoxConstraints(maxHeight: 0.88.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 44.w,
              height: 5.h,
              margin: EdgeInsets.symmetric(vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.accentError.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  ),
                  child: Icon(Icons.local_fire_department, color: AppColors.accentError, size: 20.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trending Templates',
                        style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Pick a template style and upload your photo to remix',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: AppColors.border),

          // Template Grid
          Expanded(
            child: Obx(() {
              final trendingCards = exploreCtrl.cards.where((c) => c.isTrending).toList();
              final cards = trendingCards.isNotEmpty ? trendingCards : exploreCtrl.cards.toList();

              if (cards.isEmpty && exploreCtrl.isInitialLoading.value) {
                return Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              if (cards.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_outlined, size: 48.sp, color: AppColors.textMuted),
                      SizedBox(height: 12.h),
                      Text(
                        'No templates available right now',
                        style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textSecondary),
                      ),
                      SizedBox(height: 8.h),
                      TextButton.icon(
                        onPressed: () => exploreCtrl.fetchExploreCards(isRefresh: true),
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(14.w),
                physics: const BouncingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 0.68,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return _TemplateCard(
                    card: card,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                      TemplatePhotoRemixBottomSheet.show(context, card);
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final ExploreCardModel card;
  final VoidCallback onTap;

  const _TemplateCard({required this.card, required this.onTap});

  String get _resolvedPrompt {
    if (card.fullPrompt.isNotEmpty && !card.fullPrompt.contains('[Secret Recipe Encrypted]')) {
      return card.fullPrompt;
    }
    return card.maskedSummary.replaceAll(' • [Secret Recipe Encrypted]', '');
  }

  @override
  Widget build(BuildContext context) {
    final promptText = _resolvedPrompt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8.r,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: card.previewUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surfaceLight),
              errorWidget: (_, __, ___) => Icon(Icons.broken_image, color: AppColors.textMuted),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.72),
                      Colors.black.withValues(alpha: 0.94),
                    ],
                    stops: const [0.25, 0.45, 0.72, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8.h,
              left: 8.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
                child: Text(
                  card.category,
                  style: AppTextStyles.captionXs.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Positioned(
              bottom: 8.h,
              left: 8.w,
              right: 8.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionBold.copyWith(
                      color: Colors.white,
                      fontSize: 12.sp,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.7),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 1.h, right: 3.w),
                          child: Icon(Icons.auto_awesome, size: 9.sp, color: AppColors.primary),
                        ),
                        Expanded(
                          child: Text(
                            promptText,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionXs.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 9.sp,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Icon(Icons.bolt, size: 11.sp, color: AppColors.accentWarning),
                      SizedBox(width: 2.w),
                      Text(
                        card.modelUsed,
                        style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary, fontSize: 9.sp),
                      ),
                      const Spacer(),
                      Icon(Icons.crop_free_rounded, size: 10.sp, color: AppColors.textSecondary),
                      SizedBox(width: 2.w),
                      Text(
                        card.aspectRatio,
                        style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary, fontSize: 9.sp),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
