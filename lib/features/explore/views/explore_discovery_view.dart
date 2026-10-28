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
import 'package:craftai_studio_mobile/features/explore/widgets/image_details_bottom_sheet.dart';
import 'package:craftai_studio_mobile/features/library/widgets/save_to_collection_sheet.dart';

/// [ExploreDiscoveryView] implements Screen 2 of the TL funnel:
/// - TOP: Horizontal carousel of similar-style creations
/// - BOTTOM: Vertical scrolling feed of other community artworks
/// - Tapping ANY card in either list opens [ImageDetailsBottomSheet].
class ExploreDiscoveryView extends StatefulWidget {
  final ExploreCardModel selectedCard;

  const ExploreDiscoveryView({super.key, required this.selectedCard});

  @override
  State<ExploreDiscoveryView> createState() => _ExploreDiscoveryViewState();
}

class _ExploreDiscoveryViewState extends State<ExploreDiscoveryView> {
  late final ExploreController _controller;
  late final List<ExploreCardModel> _similarCards;
  late final List<ExploreCardModel> _otherCommunityCards;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ExploreController>();

    // Partition cards:
    // 1. Similar cards: same category or style (excluding the current card if > 1)
    final sameCategory = _controller.cards
        .where((c) => c.category == widget.selectedCard.category && c.id != widget.selectedCard.id)
        .toList();

    // If same category has fewer than 4 items, backfill from other styles
    if (sameCategory.length < 4) {
      final backfill = _controller.cards
          .where((c) => c.category != widget.selectedCard.category && c.id != widget.selectedCard.id)
          .toList();
      _similarCards = [widget.selectedCard, ...sameCategory, ...backfill].take(8).toList();
    } else {
      _similarCards = [widget.selectedCard, ...sameCategory].take(8).toList();
    }

    // 2. Community stream: all cards excluding the ones in similar carousel
    final similarIds = _similarCards.map((c) => c.id).toSet();
    _otherCommunityCards = _controller.cards.where((c) => !similarIds.contains(c.id)).toList();
    if (_otherCommunityCards.isEmpty) {
      _otherCommunityCards.addAll(_controller.cards);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Explore & Discover',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: AppColors.textPrimary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: () {
              SaveToCollectionSheet.show(
                context,
                itemId: widget.selectedCard.id,
                imageUrl: widget.selectedCard.previewUrl,
              );
            },
          ),
          SizedBox(width: 4.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===================================================================
          // SECTION 1 (TOP): Horizontal Similar Creations Carousel
          // ===================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 4.w,
                          height: 18.h,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            'Similar Creations (${widget.selectedCard.category})',
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              fontSize: 15.sp,
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
                    '${_similarCards.length} styles',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // Horizontal Carousel Builder
          SliverToBoxAdapter(
            child: SizedBox(
              height: 200.h,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                itemCount: _similarCards.length,
                separatorBuilder: (_, __) => SizedBox(width: 12.w),
                itemBuilder: (context, idx) {
                  final card = _similarCards[idx];
                  final isCurrentCard = card.id == widget.selectedCard.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ImageDetailsBottomSheet.show(context, card);
                    },
                    child: Container(
                      width: 140.w,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(
                          color: isCurrentCard ? AppColors.primary : AppColors.border,
                          width: isCurrentCard ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Preview Image
                          Expanded(
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: card.previewUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surfaceLight,
                                      child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                                if (isCurrentCard)
                                  Positioned(
                                    top: 6.h,
                                    left: 6.w,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                                      ),
                                      child: Text(
                                        'Selected',
                                        style: AppTextStyles.captionXs.copyWith(
                                          color: AppColors.surface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Card Mini Footer
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.title,
                                  style: AppTextStyles.captionBold.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 11.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2.h),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        card.authorHandle,
                                        style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Row(
                                      children: [
                                        Icon(Icons.favorite, size: 10.sp, color: AppColors.accentError),
                                        SizedBox(width: 2.w),
                                        Text(
                                          '${card.likeCount}',
                                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
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
                },
              ),
            ),
          ),

          // ===================================================================
          // SECTION 2 (BOTTOM): Vertical Community Creations Stream
          // ===================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 8.h),
              child: Row(
                children: [
                  Container(
                    width: 4.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'More from the Community',
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 15.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Vertical Community Stream List
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, idx) {
                  final card = _otherCommunityCards[idx];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 12.h),
                    child: _buildCommunityListCard(card),
                  );
                },
                childCount: _otherCommunityCards.length,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(height: 32.h),
          ),
        ],
      ),
    );
  }

  /// Horizontal community list row item
  Widget _buildCommunityListCard(ExploreCardModel card) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ImageDetailsBottomSheet.show(context, card);
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Image
            SizedBox(
              width: 110.w,
              height: 110.h,
              child: CachedNetworkImage(
                imageUrl: card.previewUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.surfaceLight,
                  child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            // Details
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            card.category,
                            style: AppTextStyles.captionXs.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.bolt, size: 14.sp, color: AppColors.primary),
                            SizedBox(width: 2.w),
                            Text(
                              '${card.remixFee} Cr',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 8.w),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      card.title,
                      style: AppTextStyles.bodyMediumBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 14.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      card.maskedSummary,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11.sp,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          child: CachedNetworkImage(
                            imageUrl: card.authorAvatar,
                            width: 18.w,
                            height: 18.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          card.authorName,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11.sp,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            Icon(Icons.favorite_border, size: 14.sp, color: AppColors.textMuted),
                            SizedBox(width: 4.w),
                            Text(
                              '${card.likeCount}',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 11.sp),
                            ),
                            SizedBox(width: 8.w),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
