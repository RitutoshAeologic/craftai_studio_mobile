import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import '../controllers/explore_controller.dart';
import 'more_like_this_sheet.dart';

class ExploreCardDetailSheet extends StatelessWidget {
  final ExploreCardModel card;
  const ExploreCardDetailSheet({super.key, required this.card});

  static void show(BuildContext context, ExploreCardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ExploreCardDetailSheet(card: card),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.find<ExploreController>();

    return Container(
      constraints: BoxConstraints(maxHeight: 0.88.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                ),
              ),

              // Large High-Res Image Preview
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: CachedNetworkImage(
                          imageUrl: card.previewUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceLight,
                            child: const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        ),
                        child: Text(
                          card.category,
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12.h,
                      right: 12.w,
                      child: Obx(() {
                        final currentCard = controller.cards.firstWhere(
                          (c) => c.id == card.id,
                          orElse: () => card,
                        );
                        return GestureDetector(
                          onTap: () => controller.toggleLike(card.id),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentCard.isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: currentCard.isLiked ? AppColors.accentError : AppColors.white,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${currentCard.likeCount}',
                                  style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Royalty Split
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            card.title,
                            style: AppTextStyles.h2.copyWith(fontSize: 18.sp),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Text(
                            '${(card.creatorRoyaltyCut / card.remixFee * 100).toInt()}% Royalty',
                            style: AppTextStyles.captionBold.copyWith(color: AppColors.accentSuccess),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),

                    // Author info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12.r,
                          backgroundImage: CachedNetworkImageProvider(card.authorAvatar),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          card.authorName,
                          style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 13.sp),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          card.authorHandle,
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          '${card.remixCount} remixes',
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),

                    Divider(color: AppColors.border, height: 24.h),

                    // Prompt Recipe Box
                    Text(
                      'Prompt Recipe',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        card.maskedSummary,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12.sp),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // =========================================================
                    // MEIGEN DUAL-ACTION BUTTONS ROW
                    // =========================================================
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back();
                              controller.useAsPrompt(card);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                            ),
                            icon: Icon(Icons.auto_awesome, size: 16.sp, color: Colors.white),
                            label: Text(
                              'Use as Prompt',
                              style: AppTextStyles.captionBold.copyWith(color: Colors.white),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Get.back();
                              controller.useAsRef(card);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                            ),
                            icon: Icon(Icons.photo_library_outlined, size: 16.sp, color: AppColors.primary),
                            label: Text(
                              'Use as Ref',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10.h),

                    // "Remix on My Photo" Action
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Get.back();
                          controller.remixWithMyPhoto(card);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        icon: Icon(Icons.face_retouching_natural, size: 16.sp, color: AppColors.orangeAccent),
                        label: Text(
                          '⚡ Remix on My Photo (Subject Lock)',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.orangeAccent),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // More Like This (pgvector)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.bottomSheet(MoreLikeThisSheet(referenceCard: card));
                        },
                        icon: Icon(Icons.bubble_chart_outlined, size: 16.sp, color: AppColors.textMuted),
                        label: Text(
                          'Discover More Like This (pgvector)',
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
