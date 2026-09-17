import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import '../controllers/explore_controller.dart';
import '../widgets/explore_card_widget.dart';

class ExploreFeedView extends StatelessWidget {
  const ExploreFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.put(ExploreController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // HEADER BAR: Category Filter Pills (Horizontal Scroller)
            // =================================================================
            Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(vertical: 6.h),
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
                      onTap: () => controller.setCategory(cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: 1.0,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: AppTextStyles.captionBold.copyWith(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
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

            // =================================================================
            // 2-COLUMN STAGGERED MASONRY GRID FEED (Pinterest-Style Parity)
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
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12.h,
                  crossAxisSpacing: 12.w,
                  itemCount: list.length,
                  itemBuilder: (context, idx) {
                    final card = list[idx];
                    return ExploreCardWidget(card: card);
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
