import 'dart:ui';
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
import '../../../shared/widgets/interactions/bouncy_tap.dart';

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
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: AppColors.textPrimary),
            tooltip: 'Delete Collection',
            onPressed: () => _confirmDeleteCollection(context, controller, collection),
          ),
        ],
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
                            top: 8.h,
                            right: 8.w,
                            child: Tooltip(
                              message: 'Unsave from collection',
                              child: BouncyTap(
                                onTap: () async {
                                  HapticFeedback.mediumImpact();
                                  await controller.removeItemFromCollection(
                                    collectionId: collection.id,
                                    itemId: itemId,
                                  );
                                  Get.snackbar(
                                    'Image Unsaved',
                                    'Removed from "${collection.name}"',
                                    snackPosition: SnackPosition.BOTTOM,
                                    backgroundColor: AppColors.surface,
                                    colorText: AppColors.textPrimary,
                                    margin: const EdgeInsets.all(16),
                                    borderRadius: 12,
                                    duration: const Duration(seconds: 2),
                                    icon: Icon(Icons.bookmark_remove_rounded, color: AppColors.textPrimary),
                                  );
                                },
                                child: ClipOval(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                    child: Container(
                                      padding: EdgeInsets.all(6.r),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(alpha: 0.90),
                                          width: 1.2.w,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.15),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.bookmark_remove_rounded,
                                        color: Colors.black,
                                        size: 15.sp,
                                      ),
                                    ),
                                  ),
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

  /// Frosted glass confirmation dialog to delete this collection
  void _confirmDeleteCollection(
    BuildContext context,
    CollectionController controller,
    CollectionModel col,
  ) {
    bool isDeleting = false;
    Get.dialog(
      StatefulBuilder(
        builder: (dialogCtx, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1.2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 28.r,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.black,
                          size: 28.sp,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Delete Collection?',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Are you sure you want to delete "${col.name}"? Saved artwork will remain in your library.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.sp,
                          height: 1.4,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isDeleting ? null : () => Get.back(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.50),
                                side: BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () async {
                                      setDialogState(() => isDeleting = true);
                                      await controller.deleteCollection(col.id);
                                      Get.back(); // Dismiss dialog
                                      Get.back(); // Pop back to collections list view
                                      Get.snackbar(
                                        'Collection Deleted 🗑️',
                                        '"${col.name}" removed from your collections',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: AppColors.surface,
                                        colorText: AppColors.textPrimary,
                                        margin: const EdgeInsets.all(16),
                                        borderRadius: 12,
                                        duration: const Duration(seconds: 2),
                                        icon: Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess),
                                      );
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.black.withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: isDeleting
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
