import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/collection_model.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_image_detail_view.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import '../controllers/collection_controller.dart';
import '../../../shared/widgets/app_empty_state.dart';

/// [CollectionGalleryView] displays all saved images within a specific user collection.
/// Users can browse their saved images in an organic masonry grid, tap to view full details,
/// and manage/remove items from the collection.
class CollectionGalleryView extends StatelessWidget {
  final CollectionModel collection;

  const CollectionGalleryView({
    super.key,
    required this.collection,
  });

  @override
  Widget build(BuildContext context) {
    final CollectionController controller = Get.isRegistered<CollectionController>()
        ? Get.find<CollectionController>()
        : Get.put(CollectionController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              collection.name,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Obx(() {
              final items = controller.getCollectionItems(collection.id);
              final count = items.length;
              return Text(
                '$count saved image${count == 1 ? '' : 's'}',
                style: AppTextStyles.captionXs.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      body: Obx(() {
        final items = controller.getCollectionItems(collection.id);

        if (items.isEmpty) {
          return AppEmptyState(
            icon: Icons.photo_library_outlined,
            title: 'No Images Saved',
            subtitle: 'This collection doesn\'t have any saved images yet. Bookmark artwork from Explore or Studio to organize them here.',
            actionLabel: 'Explore Artworks',
            onAction: () {
              HapticFeedback.lightImpact();
              Get.back();
              if (Get.isRegistered<ShellController>()) {
                Get.find<ShellController>().switchTab(0);
              }
            },
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: controller.fetchCollections,
          child: MasonryGridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 10.w,
            crossAxisSpacing: 10.w,
            padding: EdgeInsets.symmetric(
              horizontal: AppDimens.spacingMd,
              vertical: AppDimens.vSpacingMd,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final imageUrl = item['image_url'] as String? ?? '';
              final title = item['title'] as String? ?? 'Artwork';
              final itemId = item['id']?.toString() ?? item['item_id']?.toString() ?? '$index';
              final category = item['category'] as String? ?? 'Community';

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  final exploreCard = ExploreCardModel(
                    id: itemId,
                    title: title,
                    previewUrl: imageUrl,
                    category: category,
                    maskedSummary: title,
                    fullPrompt: title,
                    authorName: 'Community Creator',
                    authorHandle: '@creator',
                    authorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop',
                    likeCount: 24,
                    remixCount: 8,
                    remixFee: 1.0,
                    creatorRoyaltyCut: 0.2,
                    isBookmarked: true,
                    createdAt: 'Just now',
                  );
                  Get.to(() => ExploreImageDetailView(card: exploreCard));
                },
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: (index % 3 == 0) ? 0.75 : 1.0,
                            child: CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: AppColors.surfaceLight,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.surfaceLight,
                                child: Icon(Icons.broken_image, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 6.h,
                            right: 6.w,
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                controller.removeItemFromCollection(
                                  collectionId: collection.id,
                                  itemId: itemId,
                                );
                              },
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: AppColors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.bookmark_remove_rounded,
                                  color: AppColors.white,
                                  size: 15.sp,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.r),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 11.5.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
