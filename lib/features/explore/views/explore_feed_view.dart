import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import '../controllers/explore_controller.dart';
import '../widgets/explore_card_widget.dart';
import '../widgets/filter_bottom_sheet.dart';

/// [ExploreFeedView] represents Screen 1 of the TL Explore Funnel:
/// Displays artwork in an organic Scattered Masonry grid with chunked category pills
/// and direct 1-tap navigation into [ExploreDiscoveryView].
class ExploreFeedView extends StatelessWidget {
  const ExploreFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.put(ExploreController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Explore Feed',
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.textPrimary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Filter Creations',
            onPressed: () {
              HapticFeedback.lightImpact();
              FilterBottomSheet.show(context);
            },
          ),
          SizedBox(width: 4.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // CHUNKED CATEGORY FILTER PILLS (Miller's Law 7 +/- 2)
            // =================================================================
            Container(
              height: 54.h,
              color: AppColors.surface,
              padding: EdgeInsets.symmetric(vertical: 8.h),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: controller.categories.length,
                separatorBuilder: (_, __) => SizedBox(width: 8.w),
                itemBuilder: (context, idx) {
                  final cat = controller.categories[idx];
                  return Obx(() {
                    final isSelected = controller.selectedCategory.value == cat;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        controller.setCategory(cat);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        constraints: const BoxConstraints(minHeight: 44),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: AppTextStyles.captionBold.copyWith(
                              color: isSelected ? AppColors.surface : AppColors.textSecondary,
                              fontSize: 12.sp,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                },
              ),
            ),

            Divider(height: 1, color: AppColors.border),

            // =================================================================
            // SCATTERED MASONRY GRID (Pinterest / Collage Aesthetic)
            // =================================================================
            Expanded(
              child: Obx(() {
                final list = controller.filteredCards;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search, size: 48.sp, color: AppColors.textMuted),
                        SizedBox(height: 12.h),
                        Text(
                          'No creations found in this category',
                          style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textSecondary),
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
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final card = list[idx];
                    return ExploreCardWidget(
                      card: card,
                      index: idx,
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
