import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/explore/widgets/explore_card_widget.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_category_view.dart';
import 'package:craftai_studio_mobile/features/library/widgets/save_to_collection_sheet.dart';

/// [ExploreImageDetailView] is the dedicated full-page screen for exploring
/// artwork details, generation parameters, prompt recipes, and related community creations.
///
/// Implements:
/// - Full-page transition replacing the modal bottom sheet
/// - 3 structured visual chunks (Visual Identity, Creative Recipe, Technical Parameters)
/// - Sticky ergonomic bottom bar with dominant 1-Primary CTA (⚡ Remix in Studio)
/// - Bottom "Similar Creations" section in a scattered masonry grid layout
/// - Category pill navigation to [ExploreCategoryView]
class ExploreImageDetailView extends StatefulWidget {
  final ExploreCardModel card;

  const ExploreImageDetailView({
    super.key,
    required this.card,
  });

  @override
  State<ExploreImageDetailView> createState() => _ExploreImageDetailViewState();
}

class _ExploreImageDetailViewState extends State<ExploreImageDetailView> {
  late final ExploreController _controller;
  List<ExploreCardModel> _similarCards = [];
  bool _isPromptExpanded = false;
  bool _isAdvancedSpecsOpen = false;
  bool _isCopied = false;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<ExploreController>();
    _initSimilarCards();
  }

  void _initSimilarCards() {
    // 1. Instant local category matching
    final sameCategory = _controller.cards
        .where((c) => c.category == widget.card.category && c.id != widget.card.id)
        .toList();

    if (sameCategory.length < 4) {
      final backfill = _controller.cards
          .where((c) => c.category != widget.card.category && c.id != widget.card.id)
          .toList();
      _similarCards = [...sameCategory, ...backfill].take(8).toList();
    } else {
      _similarCards = sameCategory.take(8).toList();
    }

    // 2. Asynchronously fetch pgvector/category similar creations from backend
    if (!Platform.environment.containsKey('FLUTTER_TEST') && !Get.testMode) {
      _controller.fetchSimilarCreations(widget.card.id).then((cloudSimilar) {
        if (mounted && cloudSimilar.isNotEmpty) {
          setState(() {
            _similarCards = cloudSimilar.where((c) => c.id != widget.card.id).take(8).toList();
          });
        }
      });
    }
  }

  void _copyPromptToClipboard() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.card.fullPrompt));
    setState(() => _isCopied = true);

    Get.snackbar(
      'Prompt Copied! 📋',
      'The creative recipe has been copied to your clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      borderColor: AppColors.border,
      borderWidth: 1,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.w),
      icon: Icon(Icons.check_circle_outline, color: AppColors.accentSuccess),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  void _copySeedToClipboard() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.card.seed.toString()));
    Get.snackbar(
      'Seed Copied',
      '#${widget.card.seed} copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      borderColor: AppColors.border,
      borderWidth: 1,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.w),
    );
  }

  void _shareArtwork() {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: widget.card.previewUrl));
    Get.snackbar(
      'Link Copied',
      'Artwork URL copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      borderColor: AppColors.border,
      borderWidth: 1,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.all(16.w),
      icon: Icon(Icons.share, color: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          tooltip: 'Back',
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.back();
          },
        ),
        title: Text(
          widget.card.title,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border, color: AppColors.textPrimary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Save to Collection',
            onPressed: () {
              HapticFeedback.lightImpact();
              SaveToCollectionSheet.show(
                context,
                itemId: widget.card.id,
                imageUrl: widget.card.previewUrl,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.share_outlined, color: AppColors.textPrimary),
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            tooltip: 'Share Artwork',
            onPressed: _shareArtwork,
          ),
          SizedBox(width: 4.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      bottomNavigationBar: _buildErgonomicBottomBar(_controller),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ===================================================================
          // IMAGE DETAILS CHUNKS (Miller's Law 3-Chunk Partitioning)
          // ===================================================================
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 14.h),

                  // CHUNK 1: Visual Identity & Hero Preview
                  _buildVisualIdentityChunk(_controller),
                  SizedBox(height: 16.h),

                  // CHUNK 2: Creative Recipe & Prompt
                  _buildCreativeRecipeChunk(),
                  SizedBox(height: 16.h),

                  // CHUNK 3: Technical Parameters Grid & Accordion
                  _buildTechnicalParametersChunk(),
                  SizedBox(height: 24.h),

                  // SECTION: Similar Creations Header
                  _buildSimilarCreationsHeader(),
                  SizedBox(height: 12.h),
                ],
              ),
            ),
          ),

          // ===================================================================
          // SIMILAR CREATIONS SCATTERED MASONRY GRID (Consistent with Explore)
          // ===================================================================
          if (_similarCards.isNotEmpty)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 32.h),
              sliver: SliverMasonryGrid.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12.h,
                crossAxisSpacing: 12.w,
                itemBuilder: (context, idx) {
                  final similarCard = _similarCards[idx];
                  return ExploreCardWidget(
                    card: similarCard,
                    index: idx,
                    showCategory: false,
                  );
                },
                childCount: _similarCards.length,
              ),
            )
          else
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
                child: Center(
                  child: Text(
                    'No similar creations found',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// CHUNK 1: Hero preview, clickable category chip, author row, and interactive like button
  Widget _buildVisualIdentityChunk(ExploreController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Artwork Preview
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: CachedNetworkImage(
                  imageUrl: widget.card.previewUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppColors.surfaceLight,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppColors.surfaceLight,
                    child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 40),
                  ),
                ),
              ),

              // Category Chip with navigation to ExploreCategoryView (Top-left)
              Positioned(
                top: 12.h,
                left: 12.w,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Get.to(() => ExploreCategoryView(category: widget.card.category));
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.category_outlined, size: 12.sp, color: AppColors.surface),
                        SizedBox(width: 4.w),
                        Text(
                          widget.card.category,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.surface,
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(width: 2.w),
                        Icon(Icons.chevron_right, size: 14.sp, color: AppColors.surface),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Author Row & Like Counter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  child: CachedNetworkImage(
                    imageUrl: widget.card.authorAvatar,
                    width: 38.w,
                    height: 38.h,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Icon(Icons.account_circle, color: AppColors.textMuted, size: 38),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.card.authorName,
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 13.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.card.authorHandle,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                // Interactive Like Target (min 48dp hit area)
                Obx(() {
                  final liveCard = controller.cards.firstWhere(
                    (c) => c.id == widget.card.id,
                    orElse: () => widget.card,
                  );
                  return InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.toggleLike(widget.card.id);
                    },
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: liveCard.isLiked
                            ? AppColors.accentError.withValues(alpha: 0.1)
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        border: Border.all(
                          color: liveCard.isLiked ? AppColors.accentError : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            liveCard.isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 18.sp,
                            color: liveCard.isLiked ? AppColors.accentError : AppColors.textSecondary,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '${liveCard.likeCount}',
                            style: AppTextStyles.captionBold.copyWith(
                              color: liveCard.isLiked ? AppColors.accentError : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// CHUNK 2: Creative recipe badges, expandable prompt, and 1-tap copy
  Widget _buildCreativeRecipeChunk() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Model and Tool Badges Row
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildBadge(Icons.auto_awesome, widget.card.modelUsed),
              _buildBadge(Icons.build_circle_outlined, widget.card.toolApplied),
              _buildBadge(Icons.token_outlined, '${widget.card.costCredits} Cr'),
            ],
          ),
          SizedBox(height: 12.h),

          // Master Prompt Header with 1-Tap Copy Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Prompt Recipe',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              InkWell(
                onTap: _copyPromptToClipboard,
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isCopied ? Icons.check : Icons.copy,
                        size: 15.sp,
                        color: _isCopied ? AppColors.accentSuccess : AppColors.primary,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _isCopied ? 'Copied' : 'Copy Prompt',
                        style: AppTextStyles.captionBold.copyWith(
                          color: _isCopied ? AppColors.accentSuccess : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Prompt Text with Expand/Collapse toggle
          GestureDetector(
            onTap: () => setState(() => _isPromptExpanded = !_isPromptExpanded),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.card.fullPrompt,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.45,
                    fontSize: 13.sp,
                  ),
                  maxLines: _isPromptExpanded ? 20 : 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  _isPromptExpanded ? 'Show Less ▴' : 'Show More ▾',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// CHUNK 3: 2x2 Technical Parameters Grid and Accordion
  Widget _buildTechnicalParametersChunk() {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generation Parameters',
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: 13.sp,
            ),
          ),
          SizedBox(height: 10.h),

          // 2x2 Technical Grid
          Row(
            children: [
              Expanded(
                child: _buildParameterTile(
                  label: 'Aspect Ratio',
                  value: widget.card.aspectRatio,
                  icon: Icons.aspect_ratio,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildParameterTile(
                  label: 'Dimensions',
                  value: widget.card.dimensions,
                  icon: Icons.photo_size_select_actual_outlined,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _copySeedToClipboard,
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  child: _buildParameterTile(
                    label: 'Seed # (Tap to copy)',
                    value: '#${widget.card.seed}',
                    icon: Icons.tag,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: _buildParameterTile(
                  label: 'Creation Cost',
                  value: '${widget.card.costCredits} Credits',
                  icon: Icons.bolt,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Progressive Disclosure Accordion for Advanced Specs
          InkWell(
            onTap: () => setState(() => _isAdvancedSpecsOpen = !_isAdvancedSpecsOpen),
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Advanced Generation Specs',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
                  ),
                  Icon(
                    _isAdvancedSpecsOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          if (_isAdvancedSpecsOpen) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Negative Prompt:',
                    style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.card.negativePrompt,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.3),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sampling Steps: 4 (Lightning)', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                      Text('CFG Scale: 1.5', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Section Header for Similar Creations with 1-tap navigation to the Category page
  Widget _buildSimilarCreationsHeader() {
    return Row(
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
                  'Similar Creations',
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
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Get.to(() => ExploreCategoryView(category: widget.card.category));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'View All (${widget.card.category})',
                style: AppTextStyles.captionBold.copyWith(
                  color: AppColors.primary,
                  fontSize: 11.sp,
                ),
              ),
              Icon(Icons.chevron_right, size: 14.sp, color: AppColors.primary),
            ],
          ),
        ),
      ],
    );
  }

  /// Ergonomic Bottom Bar (Hick's 1-CTA + Fitts's Thumb Zone)
  Widget _buildErgonomicBottomBar(ExploreController controller) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border, width: 1.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Dominant Primary CTA: Remix in Studio (Full Width, 52dp)
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Get.back();
                  controller.useAsPrompt(widget.card);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                ),
                icon: const Icon(Icons.bolt, size: 22),
                label: Text(
                  '⚡ Remix in Studio',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.surface,
                    fontSize: 15.sp,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.h),

            // Secondary Action Icons Row (min 48dp hit targets)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSecondaryActionButton(
                  icon: Icons.bookmark_add_outlined,
                  label: 'Save',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    SaveToCollectionSheet.show(
                      context,
                      itemId: widget.card.id,
                      imageUrl: widget.card.previewUrl,
                    );
                  },
                ),
                _buildSecondaryActionButton(
                  icon: Icons.image_outlined,
                  label: 'Use Ref',
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Get.back();
                    controller.useAsRef(widget.card);
                  },
                ),
                _buildSecondaryActionButton(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  onTap: _shareArtwork,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13.sp, color: AppColors.primary),
          SizedBox(width: 4.w),
          Flexible(
            child: Text(
              text,
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.textPrimary,
                fontSize: 11.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParameterTile({required String label, required String value, required IconData icon}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.sp, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, fontSize: 10.sp),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            value,
            style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary, fontSize: 13.sp),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
      child: Container(
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: AppColors.textSecondary),
            SizedBox(width: 4.w),
            Text(
              label,
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
