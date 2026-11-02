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

/// [ExploreFeedView] displays community artwork in an organic Scattered Masonry grid
/// with 3 primary dropdown filters at the top: Categories, Models, and Aspect Ratio.
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
        title: Obx(() {
          if (controller.isSearching.value) {
            return TextField(
              autofocus: true,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search prompts, artists, styles...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: controller.setSearchQuery,
            );
          }
          return Text(
            'Explore Feed',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          );
        }),
        actions: [
          Obx(() {
            if (controller.isSearching.value) {
              return IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Clear search',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.clearSearch();
                },
              );
            }
            return IconButton(
              icon: const Icon(Icons.search, color: AppColors.textPrimary),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              tooltip: 'Search creations',
              onPressed: () {
                HapticFeedback.lightImpact();
                controller.isSearching.value = true;
              },
            );
          }),
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
            // THREE PRIMARY DROPDOWN FILTERS: Categories, Models, Aspect Ratio
            // =================================================================
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Obx(() {
                final selectedCategory = controller.selectedCategory.value;
                final selectedModel = controller.selectedModel.value;
                final selectedRatio = controller.selectedAspectRatios.contains('All')
                    ? 'All'
                    : controller.selectedAspectRatios.first;

                return Row(
                  children: [
                    // Dropdown 1: Categories
                    Expanded(
                      child: _buildFilterDropdown(
                        title: 'Categories',
                        value: selectedCategory,
                        items: controller.categories,
                        isDefault: selectedCategory == 'All',
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            controller.setCategory(val);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Dropdown 2: Models
                    Expanded(
                      child: _buildFilterDropdown(
                        title: 'Models',
                        value: selectedModel,
                        items: controller.models,
                        isDefault: selectedModel == 'All Models',
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            controller.setModel(val);
                          }
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),

                    // Dropdown 3: Aspect Ratio
                    Expanded(
                      child: _buildFilterDropdown(
                        title: 'Aspect Ratio',
                        value: selectedRatio,
                        items: controller.aspectRatios,
                        isDefault: selectedRatio == 'All',
                        onChanged: (val) {
                          if (val != null) {
                            HapticFeedback.selectionClick();
                            controller.setAspectRatio(val);
                          }
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),

            Divider(height: 1, color: AppColors.border),

            // =================================================================
            // SCATTERED MASONRY GRID (Consistent Sketcher-Style Layout)
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
                          'No creations found matching filters',
                          style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textSecondary),
                        ),
                        SizedBox(height: 8.h),
                        TextButton.icon(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.resetFilters();
                          },
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Reset All Filters'),
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

  /// Reusable Dropdown Filter Component with dynamic active styling
  Widget _buildFilterDropdown({
    required String title,
    required String value,
    required List<String> items,
    required bool isDefault,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : items.first;
    final displayText = isDefault ? title : value;

    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      decoration: BoxDecoration(
        color: !isDefault
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
        border: Border.all(
          color: !isDefault ? AppColors.primary : AppColors.border,
          width: !isDefault ? 1.5 : 1.0,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 18.sp,
            color: !isDefault ? AppColors.primary : AppColors.textSecondary,
          ),
          selectedItemBuilder: (context) {
            return items.map((item) {
              return Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  displayText,
                  style: AppTextStyles.captionBold.copyWith(
                    color: !isDefault ? AppColors.primary : AppColors.textPrimary,
                    fontSize: 11.5.sp,
                    fontWeight: !isDefault ? FontWeight.w800 : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: items.map((item) {
            final isItemDefault = item == 'All' || item == 'All Models';
            final isItemSelected = item == safeValue;
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isItemSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                        fontWeight: isItemSelected
                            ? FontWeight.bold
                            : (isItemDefault ? FontWeight.w600 : FontWeight.normal),
                        fontSize: 13.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isItemSelected)
                    Icon(
                      Icons.check,
                      size: 16.sp,
                      color: AppColors.primary,
                    ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
