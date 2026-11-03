import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/remix/views/remix_chat_view.dart';

class ProductPackPreviewSheet extends StatefulWidget {
  final String productName;
  final Map<String, dynamic> pack;
  final String? originalImageUrl;

  const ProductPackPreviewSheet({
    super.key,
    required this.productName,
    required this.pack,
    this.originalImageUrl,
  });

  static Future<void> show({
    required BuildContext context,
    required String productName,
    required Map<String, dynamic> pack,
    String? originalImageUrl,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductPackPreviewSheet(
        productName: productName,
        pack: pack,
        originalImageUrl: originalImageUrl,
      ),
    );
  }

  @override
  State<ProductPackPreviewSheet> createState() => _ProductPackPreviewSheetState();
}

class _ProductPackPreviewSheetState extends State<ProductPackPreviewSheet> {
  int _selectedIndex = 0;

  late final List<Map<String, dynamic>> _formats;

  @override
  void initState() {
    super.initState();
    _formats = [
      {
        'key': 'amazon_white',
        'title': 'Amazon White',
        'ratio': '1:1',
        'aspectRatio': 1.0,
        'icon': '🛒',
        'desc': 'Pure white background (#FFFFFF) compliant with Amazon & Walmart standards',
        'url': widget.pack['amazon_white'] as String? ?? '',
      },
      {
        'key': 'studio_pedestal',
        'title': 'Studio Pedestal',
        'ratio': '4:5',
        'aspectRatio': 4 / 5,
        'icon': '🏛️',
        'desc': 'Luxury marble podium with overhead keylight for premium Shopify catalog',
        'url': widget.pack['studio_pedestal'] as String? ?? '',
      },
      {
        'key': 'lifestyle_table',
        'title': 'Lifestyle Scene',
        'ratio': '4:5',
        'aspectRatio': 4 / 5,
        'icon': '☕',
        'desc': 'Cozy warm interior table setting for social commerce conversions',
        'url': widget.pack['lifestyle_table'] as String? ?? '',
      },
      {
        'key': 'story_flyer',
        'title': 'Story Flyer',
        'ratio': '9:16',
        'aspectRatio': 9 / 16,
        'icon': '📱',
        'desc': 'Vertical storytelling visual with typography header for IG & TikTok ads',
        'url': widget.pack['story_flyer'] as String? ?? '',
      },
    ];
  }

  void _saveAllToLibrary() {
    if (Get.isRegistered<LibraryController>()) {
      final lib = LibraryController.to;
      int savedCount = 0;
      for (final f in _formats) {
        final url = f['url'] as String;
        if (url.isNotEmpty) {
          lib.addNewCreation(
            prompt: 'Pack: ${widget.productName} (${f['title']})',
            credits: 0.0,
            previewUrl: url,
            type: 'PRODUCT_PACK_ITEM',
            metadata: {
              'product_name': widget.productName,
              'format': f['key'],
              'ratio': f['ratio'],
            },
          );
          savedCount++;
        }
      }
      Get.snackbar(
        'Saved to Library! 📦',
        'Successfully added all $savedCount listing formats to your creation gallery.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentSuccess,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentFormat = _formats[_selectedIndex];
    final currentUrl = currentFormat['url'] as String;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 10.h, bottom: 8.h),
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8.w,
                          children: [
                            Text(
                              'E-Commerce 4-Pack',
                              style: AppTextStyles.h2.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                              ),
                              child: Text(
                                '4 Listings in 1',
                                style: AppTextStyles.captionXs.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.productName,
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1.h, color: AppColors.border),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Main Active Preview Card
                    Container(
                      constraints: BoxConstraints(
                        minHeight: 220.h,
                        maxHeight: 360.h,
                      ),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: currentFormat['aspectRatio'] as double,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: currentUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: currentUrl,
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) => Container(
                                      color: AppColors.surface,
                                      child: const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surface,
                                      child: const Center(
                                        child: Icon(Icons.broken_image, color: AppColors.textMuted),
                                      ),
                                    ),
                                  )
                                : const Center(child: Text('No image available')),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // Active Format Description Banner
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Text(currentFormat['icon'] as String, style: TextStyle(fontSize: 18.sp)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6.w,
                                  children: [
                                    Text(
                                      currentFormat['title'] as String,
                                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4.r),
                                      ),
                                      child: Text(
                                        currentFormat['ratio'] as String,
                                        style: AppTextStyles.captionXs.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  currentFormat['desc'] as String,
                                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary, fontSize: 10.sp),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 14.h),

                    // Format Thumbnail Strip (1-tap switch)
                    Row(
                      children: List.generate(_formats.length, (idx) {
                        final fmt = _formats[idx];
                        final isSelected = idx == _selectedIndex;
                        final url = fmt['url'] as String;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedIndex = idx),
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 3.w),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                border: Border.all(
                                  color: isSelected ? AppColors.primary : AppColors.border,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              child: Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusSm - 1)),
                                    child: SizedBox(
                                      height: 64.h,
                                      width: double.infinity,
                                      child: url.isNotEmpty
                                          ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                                          : Container(color: AppColors.surface),
                                    ),
                                  ),
                                  Container(
                                    padding: EdgeInsets.symmetric(vertical: 4.h),
                                    width: double.infinity,
                                    color: isSelected ? AppColors.primary.withValues(alpha: 0.10) : AppColors.surface,
                                    child: Text(
                                      fmt['ratio'] as String,
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.captionXs.copyWith(
                                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 9.sp,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: 16.h),

                    // Primary Action: Save All 4 to Library
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        ),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.bookmark_add_outlined, size: 18, color: Colors.white),
                      label: Text(
                        'Save All 4 Formats to Library',
                        style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 14.sp),
                      ),
                      onPressed: _saveAllToLibrary,
                    ),

                    SizedBox(height: 8.h),

                    // Secondary Action: Remix in Lab
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        ),
                      ),
                      icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
                      label: Text(
                        'Remix Active Format in Lab',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                      ),
                      onPressed: () {
                        if (currentUrl.isNotEmpty) {
                          Navigator.of(context).pop();
                          Get.to(
                            () => const RemixChatView(),
                            arguments: {
                              'anchorImageUrl': currentUrl,
                              'initialPrompt': 'Refine: ${widget.productName} (${currentFormat['title']})',
                              'sourceType': 'product_pack',
                            },
                          );
                        }
                      },
                    ),

                    SizedBox(height: 8.h),

                    // Studio Canvas & Done row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              ),
                            ),
                            icon: Icon(Icons.palette_outlined, size: 16.sp, color: AppColors.textPrimary),
                            label: Text(
                              'Canvas',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                            onPressed: () {
                              if (currentUrl.isNotEmpty) {
                                Navigator.of(context).pop();
                                if (Get.isRegistered<StudioController>()) {
                                  Get.find<StudioController>().addReferenceImage(currentUrl);
                                }
                                if (Get.isRegistered<ShellController>()) {
                                  ShellController.to.switchTab(1);
                                }
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              elevation: 0,
                            ),
                            icon: Icon(Icons.check, size: 16.sp, color: AppColors.accentSuccess),
                            label: Text(
                              'Done',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
