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
import 'package:craftai_studio_mobile/features/library/widgets/save_to_collection_sheet.dart';

/// [ImageDetailsBottomSheet] is the central inspection modal for Explore artwork.
/// It strictly implements Miller's Law (3 chunked cards), Hick's Law (1 Primary CTA),
/// and Fitts's Law (thumb-zone bottom sticky bar with >= 48dp touch targets).
class ImageDetailsBottomSheet extends StatefulWidget {
  final ExploreCardModel card;

  const ImageDetailsBottomSheet({super.key, required this.card});

  static void show(BuildContext context, ExploreCardModel card) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ImageDetailsBottomSheet(card: card),
    );
  }

  @override
  State<ImageDetailsBottomSheet> createState() => _ImageDetailsBottomSheetState();
}

class _ImageDetailsBottomSheetState extends State<ImageDetailsBottomSheet> {
  bool _isPromptExpanded = false;
  bool _isAdvancedSpecsOpen = false;
  bool _isCopied = false;

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
      icon: const Icon(Icons.check_circle_outline, color: AppColors.accentSuccess),
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

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.find<ExploreController>();

    return Container(
      constraints: BoxConstraints(maxHeight: 0.92.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Pill Drag Handle
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                margin: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
            ),

            // Scrollable 3-Chunk Inspection Body
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // CHUNK 1: Visual Identity & Hero Preview
                    // =========================================================
                    _buildVisualIdentityChunk(controller),
                    SizedBox(height: 16.h),

                    // =========================================================
                    // CHUNK 2: Creative Recipe & Prompt
                    // =========================================================
                    _buildCreativeRecipeChunk(),
                    SizedBox(height: 16.h),

                    // =========================================================
                    // CHUNK 3: Technical Parameters Grid & Accordion
                    // =========================================================
                    _buildTechnicalParametersChunk(),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // =================================================================
            // FITTS'S LAW ERGONOMIC STICKY BOTTOM BAR (Natural Thumb Zone)
            // =================================================================
            _buildErgonomicBottomBar(controller),
          ],
        ),
      ),
    );
  }

  /// CHUNK 1: Hero preview, author pill, and like button
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
                    child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                  ),
                ),
              ),
              // Category Chip (Top-left)
              Positioned(
                top: 12.h,
                left: 12.w,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                  child: Text(
                    widget.card.category,
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.surface,
                      fontSize: 11.sp,
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
                    width: 36.w,
                    height: 36.h,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(Icons.account_circle, color: AppColors.textMuted),
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
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
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
                Navigator.of(context).pop();
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
                  Navigator.of(context).pop();
                  controller.useAsRef(widget.card);
                },
              ),
              _buildSecondaryActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                onTap: () {
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
                  );
                },
              ),
            ],
          ),
        ],
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.sp, color: AppColors.textSecondary),
            SizedBox(width: 6.w),
            Text(
              label,
              style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
