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
/// Features infinite scrolling pagination, dynamic loaders, error recovery, and filter badges.
class ExploreFeedView extends StatefulWidget {
  const ExploreFeedView({super.key});

  @override
  State<ExploreFeedView> createState() => _ExploreFeedViewState();
}

class _ExploreFeedViewState extends State<ExploreFeedView> {
  late final ScrollController _scrollController;
  late final ExploreController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ExploreController>()
        ? Get.find<ExploreController>()
        : Get.put(ExploreController());
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // Trigger next page when user reaches within 300px of bottom
    if (currentScroll >= maxScroll - 300) {
      if (!_controller.isLoadingMore.value &&
          _controller.hasMoreCards.value &&
          _controller.paginationError.value == null &&
          !_controller.isInitialLoading.value) {
        _controller.loadMoreCards();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Obx(() {
          if (_controller.isSearching.value) {
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
              onChanged: _controller.setSearchQuery,
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
            if (_controller.isSearching.value) {
              return IconButton(
                icon: Icon(Icons.close, color: AppColors.textPrimary),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                tooltip: 'Clear search',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _controller.clearSearch();
                },
              );
            }
            return IconButton(
              icon: Icon(Icons.search, color: AppColors.textPrimary),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              tooltip: 'Search creations',
              onPressed: () {
                HapticFeedback.lightImpact();
                _controller.isSearching.value = true;
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
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================================
            // THREE PRIMARY DROPDOWN FILTERS + ACTIVE FILTER BADGE
            // =================================================================
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Obx(() {
                final selectedCategory = _controller.selectedCategory.value;
                final selectedModel = _controller.selectedModel.value;
                final selectedRatio = _controller.selectedAspectRatios.contains('All')
                    ? 'All'
                    : _controller.selectedAspectRatios.first;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Dropdown 1: Categories
                        Expanded(
                          child: _buildFilterDropdown(
                            title: 'Categories',
                            value: selectedCategory,
                            items: _controller.categories,
                            isDefault: selectedCategory == 'All',
                            onChanged: (val) {
                              if (val != null) {
                                HapticFeedback.selectionClick();
                                _controller.setCategory(val);
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
                            items: _controller.models,
                            isDefault: selectedModel == 'All Models',
                            onChanged: (val) {
                              if (val != null) {
                                HapticFeedback.selectionClick();
                                _controller.setModel(val);
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
                            items: _controller.aspectRatios,
                            isDefault: selectedRatio == 'All',
                            onChanged: (val) {
                              if (val != null) {
                                HapticFeedback.selectionClick();
                                _controller.setAspectRatio(val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),

                    // Active filters indicator bar & quick reset
                    if (_controller.hasActiveFilters) ...[
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                            ),
                            child: Text(
                              '${_controller.activeFilterCount} Active Filter${_controller.activeFilterCount > 1 ? 's' : ''}',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.primary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _controller.resetFilters();
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close_rounded, size: 13.sp, color: AppColors.textSecondary),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Reset All',
                                    style: AppTextStyles.captionBold.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              }),
            ),

            Divider(height: 1, color: AppColors.border),

            // =================================================================
            // SCATTERED MASONRY GRID WITH INFINITE SCROLL & SKELETON LOADERS
            // =================================================================
            Expanded(
              child: Obx(() {
                // Initial Loading Shimmer State
                if (_controller.isInitialLoading.value && _controller.cards.isEmpty) {
                  return _buildInitialSkeleton();
                }

                final list = _controller.filteredCards;

                // Empty State with Action CTA
                if (list.isEmpty) {
                  return _buildEmptyState();
                }

                // Main Feed with Infinite Scrolling & Footer Loader
                return RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _controller.refreshCards,
                  child: CustomScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12.h,
                          crossAxisSpacing: 12.w,
                          itemBuilder: (context, idx) {
                            return ExploreCardWidget(
                              card: list[idx],
                              index: idx,
                            );
                          },
                          childCount: list.length,
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _buildPaginationFooter(context),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Initial loading skeleton for smooth visual feedback without layout flashes
  Widget _buildInitialSkeleton() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 32.w,
            height: 32.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'Curating community masterpieces...',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Context-aware empty state with reset filter CTA
  Widget _buildEmptyState() {
    final hasSearch = _controller.searchQuery.value.trim().isNotEmpty;
    final title = hasSearch ? 'No Creations Found' : 'No Matching Artwork';
    final subtitle = hasSearch
        ? 'No community prompts matched "${_controller.searchQuery.value}"'
        : 'Try adjusting or clearing your filters to discover more creations.';

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(Icons.image_search, size: 28.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: AppTextStyles.h2.copyWith(fontSize: 17.sp),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              subtitle,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 18.h),
            ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                if (hasSearch) {
                  _controller.clearSearch();
                } else {
                  _controller.resetFilters();
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(hasSearch ? 'Clear Search' : 'Reset All Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom pagination footer rendering loaders, retry pill, or end-of-feed chip
  Widget _buildPaginationFooter(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final navBarPadding = bottomInset > 0 ? bottomInset + 88.h : 96.h;

    return Padding(
      padding: EdgeInsets.only(bottom: navBarPadding),
      child: Obx(() {

      // 1. Actively loading next page
      if (_controller.isLoadingMore.value) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16.w,
                height: 16.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Discovering more creations...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }

      // 2. Pagination network or server error with 1-tap retry button
      if (_controller.paginationError.value != null) {
        return Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.lightImpact();
              _controller.loadMoreCards();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                border: Border.all(color: AppColors.accentWarning.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 15.sp, color: AppColors.accentWarning),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      'Couldn\'t reach feed • Tap to retry',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 3. Reached end of available creations
      if (!_controller.hasMoreCards.value && _controller.cards.isNotEmpty) {
        return Container(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
          alignment: Alignment.center,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 13.sp, color: AppColors.textMuted),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    'You\'re all caught up • All creations loaded ✨',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return SizedBox(height: 24.h);
    }),
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
            ? AppColors.primary.withValues(alpha: 0.10)
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
            Icons.keyboard_arrow_down_rounded,
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
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList();
          },
          items: items.map((item) {
            final isItemDefault = (item == 'All' || item == 'All Models');
            final isSelected = item == safeValue;

            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isItemDefault ? '$title ($item)' : item,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_rounded,
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
