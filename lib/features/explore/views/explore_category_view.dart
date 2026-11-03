import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/explore/widgets/explore_card_widget.dart';

/// [ExploreCategoryView] displays all artworks belonging to a specific category.
/// Rendered using the same scattered masonry grid layout consistent with the Explore screen.
class ExploreCategoryView extends StatelessWidget {
  final String category;

  const ExploreCategoryView({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.find<ExploreController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Back',
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.back();
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Obx(() {
              final count = controller.cards
                  .where((c) => c.category.toLowerCase() == category.toLowerCase())
                  .length;
              return Text(
                '$count ${count == 1 ? "creation" : "creations"}',
                style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
              );
            }),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final categoryCards = controller.cards
              .where((c) => c.category.toLowerCase() == category.toLowerCase())
              .toList();

          if (categoryCards.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_search, size: 48.sp, color: AppColors.textMuted),
                  SizedBox(height: 12.h),
                  Text(
                    'No creations found in $category',
                    style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Explore other categories or publish your own work!',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }

          return MasonryGridView.count(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            itemCount: categoryCards.length,
            itemBuilder: (context, idx) {
              final card = categoryCards[idx];
              return ExploreCardWidget(
                card: card,
                index: idx,
                showCategory: false,
              );
            },
          );
        }),
      ),
    );
  }
}

