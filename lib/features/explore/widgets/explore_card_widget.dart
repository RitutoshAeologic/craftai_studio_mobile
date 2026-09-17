import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import '../controllers/explore_controller.dart';
import 'explore_card_detail_sheet.dart';

class ExploreCardWidget extends StatelessWidget {
  final ExploreCardModel card;
  const ExploreCardWidget({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.find<ExploreController>();

    return GestureDetector(
      onTap: () => ExploreCardDetailSheet.show(context, card),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Artwork Image Preview with Overlay
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: card.previewUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 180.h,
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 180.h,
                    color: AppColors.surfaceLight,
                    child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                  ),
                ),

                // Category Tag (Top-left)
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4.r),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Text(
                      card.category,
                      style: AppTextStyles.captionXs.copyWith(
                        color: Colors.white,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Heart / Like (Top-right)
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Obx(() {
                    final currentCard = controller.cards.firstWhere(
                      (c) => c.id == card.id,
                      orElse: () => card,
                    );
                    return GestureDetector(
                      onTap: () => controller.toggleLike(card.id),
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          currentCard.isLiked ? Icons.favorite : Icons.favorite_border,
                          color: currentCard.isLiked ? AppColors.accentError : AppColors.white,
                          size: 14.sp,
                        ),
                      ),
                    );
                  }),
                ),

                // Subtle Bottom Gradient
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 40.h,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Footer
            Padding(
              padding: EdgeInsets.all(8.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 8.r,
                              backgroundImage: CachedNetworkImageProvider(card.authorAvatar),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Text(
                                card.authorHandle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.captionXs.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 9.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high, size: 10.sp, color: AppColors.primary),
                          SizedBox(width: 2.w),
                          Text(
                            '${card.remixCount}',
                            style: AppTextStyles.captionXs.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 9.sp,
                            ),
                          ),
                        ],
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
