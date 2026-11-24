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
import 'package:craftai_studio_mobile/features/explore/widgets/template_photo_remix_bottom_sheet.dart';

/// [TrendingTemplatesView] provides a dedicated, immersive full-screen discovery
/// experience for curated trending AI styles & templates, matching ChatGPT / Midjourney.
/// 
/// Tapping on any template card triggers [TemplatePhotoRemixBottomSheet] from the bottom
/// allowing the user to snap a selfie or select a photo to remix.
class TrendingTemplatesView extends StatefulWidget {
  const TrendingTemplatesView({super.key});

  @override
  State<TrendingTemplatesView> createState() => _TrendingTemplatesViewState();
}

class _TrendingTemplatesViewState extends State<TrendingTemplatesView> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  final RxString _selectedCategory = 'All'.obs;

  static const List<String> _categories = [
    'All',
    'Cyberpunk',
    'Photorealism',
    'Anime',
    'Architecture',
    'Wildlife',
    'Concept Art',
    'Surrealism',
    'Commercial',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ExploreController exploreCtrl = Get.isRegistered<ExploreController>()
        ? Get.find<ExploreController>()
        : Get.put(ExploreController());

    if (exploreCtrl.cards.isEmpty && !exploreCtrl.isInitialLoading.value) {
      exploreCtrl.fetchExploreCards(isRefresh: true);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20.sp, color: AppColors.textPrimary),
          tooltip: 'Back',
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.back();
          },
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.accentError.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
              child: Icon(
                Icons.local_fire_department_rounded,
                color: AppColors.accentError,
                size: 20.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Trending & Templates',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Pick a style & remix your photo',
                    style: AppTextStyles.captionXs.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 22.sp),
            tooltip: 'Refresh Templates',
            onPressed: () {
              HapticFeedback.lightImpact();
              exploreCtrl.fetchExploreCards(isRefresh: true);
            },
          ),
          SizedBox(width: 4.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(104.h),
          child: Column(
            children: [
              // Search Input Box
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _searchQuery.value = val.trim(),
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search styles, themes, prompts...',
                      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20.sp),
                      suffixIcon: Obx(() {
                        if (_searchQuery.value.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: Icon(Icons.cancel_rounded, size: 18.sp, color: AppColors.textMuted),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery.value = '';
                          },
                        );
                      }),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                    ),
                  ),
                ),
              ),

              // Categories Horizontal Filter Bar
              SizedBox(
                height: 38.h,
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    return Obx(() {
                      final isSelected = _selectedCategory.value.toLowerCase() == cat.toLowerCase();
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _selectedCategory.value = cat;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: AppTextStyles.caption.copyWith(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
              SizedBox(height: 8.h),
              Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          ),
        ),
      ),
      body: Obx(() {
        final query = _searchQuery.value.toLowerCase();
        final selectedCat = _selectedCategory.value.toLowerCase();

        // 1. Gather all curated trending templates
        final trendingCards = exploreCtrl.cards
            .where((c) => c.isTrending || c.id.startsWith('10000000-'))
            .toList();
        final baseList = trendingCards.isNotEmpty ? trendingCards : exploreCtrl.cards.toList();

        // 2. Filter by Category and Search Query
        final filteredList = baseList.where((card) {
          final matchesCategory = selectedCat == 'all' ||
              card.category.toLowerCase() == selectedCat;
          final matchesSearch = query.isEmpty ||
              card.title.toLowerCase().contains(query) ||
              card.fullPrompt.toLowerCase().contains(query) ||
              card.maskedSummary.toLowerCase().contains(query) ||
              card.tags.any((t) => t.toLowerCase().contains(query));
          return matchesCategory && matchesSearch;
        }).toList();

        if (exploreCtrl.isInitialLoading.value && baseList.isEmpty) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (filteredList.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.style_outlined, size: 54.sp, color: AppColors.textMuted),
                  SizedBox(height: 14.h),
                  Text(
                    'No templates found',
                    style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    query.isNotEmpty
                        ? 'Try searching with a different keyword or category'
                        : 'Tap refresh to sync latest templates',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      ),
                    ),
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery.value = '';
                      _selectedCategory.value = 'All';
                      exploreCtrl.fetchExploreCards(isRefresh: true);
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Reset Filters'),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: EdgeInsets.all(14.w),
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.68,
          ),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final card = filteredList[index];
            return _FullScreenTemplateCard(
              card: card,
              onTap: () {
                HapticFeedback.lightImpact();
                // Open Photo Remix bottom sheet over this full screen view
                TemplatePhotoRemixBottomSheet.show(context, card);
              },
            );
          },
        );
      }),
    );
  }
}

class _FullScreenTemplateCard extends StatelessWidget {
  final ExploreCardModel card;
  final VoidCallback onTap;

  const _FullScreenTemplateCard({required this.card, required this.onTap});

  String get _resolvedPrompt {
    if (card.fullPrompt.isNotEmpty && !card.fullPrompt.contains('[Secret Recipe Encrypted]')) {
      return card.fullPrompt;
    }
    return card.maskedSummary.replaceAll(' • [Secret Recipe Encrypted]', '');
  }

  @override
  Widget build(BuildContext context) {
    final promptText = _resolvedPrompt;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 10.r,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Template Visual Image
            CachedNetworkImage(
              imageUrl: card.previewUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: AppColors.surfaceLight),
              errorWidget: (_, __, ___) => Container(
                color: AppColors.surfaceLight,
                child: Center(
                  child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted),
                ),
              ),
            ),

            // Deep Gradient Overlay for High Contrast
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.0, 0.40, 0.74, 1.0],
                  ),
                ),
              ),
            ),

            // Top Badges Row (Category & Remix Count)
            Positioned(
              top: 8.h,
              left: 8.w,
              right: 8.w,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
                    ),
                    child: Text(
                      card.category,
                      style: AppTextStyles.captionXs.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.sp,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentError.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.white, size: 11.sp),
                        SizedBox(width: 2.w),
                        Text(
                          '${card.remixesCount}',
                          style: AppTextStyles.captionXs.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Content
            Positioned(
              bottom: 8.h,
              left: 8.w,
              right: 8.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionBold.copyWith(
                      color: Colors.white,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    promptText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionXs.copyWith(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10.sp,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high_rounded, color: Colors.white, size: 12.sp),
                          SizedBox(width: 4.w),
                          Text(
                            'Remix My Photo',
                            style: AppTextStyles.captionXs.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
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
