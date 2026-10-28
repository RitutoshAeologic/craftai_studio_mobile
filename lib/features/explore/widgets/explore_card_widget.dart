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
import 'package:craftai_studio_mobile/features/explore/views/explore_discovery_view.dart';

/// [ExploreCardWidget] renders an artwork card in the Scattered Masonry Explore feed.
/// Tapping the card routes directly to [ExploreDiscoveryView] as specified in the TL flow.
class ExploreCardWidget extends StatelessWidget {
  final ExploreCardModel card;
  final int index;

  const ExploreCardWidget({
    super.key,
    required this.card,
    this.index = 0,
  });

  /// Dynamic aspect ratio calculation for scattered organic visual rhythm:
  /// - index % 4 == 0 -> 4:5 (0.80)
  /// - index % 4 == 1 -> 1:1 (1.00)
  /// - index % 4 == 2 -> 3:4 (0.75)
  /// - index % 4 == 3 -> 16:9 (1.77)
  double get _dynamicAspectRatio {
    switch (index % 4) {
      case 0:
        return 0.80; // 4:5
      case 1:
        return 1.00; // 1:1
      case 2:
        return 0.75; // 3:4
      case 3:
      default:
        return 1.25; // 4:3
    }
  }

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.find<ExploreController>();

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Get.to(() => ExploreDiscoveryView(selectedCard: card));
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic Aspect Ratio Image Preview with Overlay
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: _dynamicAspectRatio,
                  child: CachedNetworkImage(
                    imageUrl: card.previewUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: AppColors.surfaceLight,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceLight,
                      child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                    ),
                  ),
                ),

                // Category Tag (Top-left)
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      border: Border.all(color: AppColors.border.withValues(alpha: 0.5), width: 0.5),
                    ),
                    child: Text(
                      card.category,
                      style: AppTextStyles.captionXs.copyWith(
                        color: AppColors.surface,
                        fontSize: 9.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Heart / Like Target with 48dp hit area (Top-right)
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: Obx(() {
                    final currentCard = controller.cards.firstWhere(
                      (c) => c.id == card.id,
                      orElse: () => card,
                    );
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.toggleLike(card.id);
                      },
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                        padding: EdgeInsets.all(6.r),
                        child: Container(
                          padding: EdgeInsets.all(4.r),
                          decoration: BoxDecoration(
                            color: AppColors.black.withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            currentCard.isLiked ? Icons.favorite : Icons.favorite_border,
                            color: currentCard.isLiked ? AppColors.accentError : AppColors.surface,
                            size: 15.sp,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),

            // Card Footer
            Padding(
              padding: EdgeInsets.all(10.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: AppTextStyles.bodyMediumBold.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        child: CachedNetworkImage(
                          imageUrl: card.authorAvatar,
                          width: 18.w,
                          height: 18.h,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.account_circle,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          card.authorHandle,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.bolt, size: 13.sp, color: AppColors.primary),
                          Text(
                            '${card.remixFee.toInt()} Cr',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 10.sp,
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
