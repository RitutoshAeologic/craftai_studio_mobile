import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/library/controllers/collection_controller.dart';

/// [SaveToCollectionSheet] is an Instagram-parity bookmark bottom sheet that enables
/// users to save creations into named folders with optimistic updates and inline creation.
class SaveToCollectionSheet extends StatefulWidget {
  final String itemId;
  final String imageUrl;

  const SaveToCollectionSheet({
    super.key,
    required this.itemId,
    required this.imageUrl,
  });

  static void show(BuildContext context, {required String itemId, required String imageUrl}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: false,
      builder: (_) => SaveToCollectionSheet(itemId: itemId, imageUrl: imageUrl),
    );
  }

  @override
  State<SaveToCollectionSheet> createState() => _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState extends State<SaveToCollectionSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleCreateCollection(CollectionController controller) async {
    if (_isSubmitting) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Prevent creating duplicate collections with the same name
    final exists = controller.collections.any(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      Get.snackbar(
        'Collection Exists',
        'A collection named "$name" already exists.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
        margin: EdgeInsets.all(16.w),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final newCol = await controller.createCollection(
        name: name,
        coverImageUrl: widget.imageUrl,
      );

      // Automatically save current item into the newly created collection
      await controller.toggleSaveItem(
        collectionId: newCol.id,
        itemId: widget.itemId,
        imageUrl: widget.imageUrl,
      );

      _nameController.clear();
      if (mounted) {
        setState(() {
          _isCreating = false;
          _isSubmitting = false;
        });
      }

      Get.snackbar(
        'Collection Created',
        'Saved to "$name"',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.primary,
        borderColor: AppColors.border,
        borderWidth: 1,
        duration: const Duration(seconds: 2),
        margin: EdgeInsets.all(16.w),
        icon: Icon(Icons.check_circle_outline, color: AppColors.accentSuccess),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final CollectionController controller = Get.put(CollectionController());
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    // When keyboard is visible, offset strictly by keyboard height without extra safe area dead space.
    // When keyboard is hidden, clear the home indicator with clean ergonomic spacing.
    final effectiveBottom = viewInsetsBottom > 0
        ? viewInsetsBottom + 8.h
        : (paddingBottom > 0 ? paddingBottom + 6.h : 16.h);

    return Container(
      constraints: BoxConstraints(maxHeight: 0.80.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: effectiveBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              // Ergonomic drag handle
              Center(
                child: Container(
                  width: 44.w,
                  height: 5.h,
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                ),
              ),

              // Sheet Header
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Save to Collection',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        fontSize: 18.sp,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: AppColors.border),

              // Inline New Collection Creator Row
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                child: _isCreating
                    ? Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              autofocus: true,
                              style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Collection name (e.g. Cyberpunk)',
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                                filled: true,
                                fillColor: AppColors.surfaceLight,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                  borderSide: BorderSide(color: AppColors.border),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                                  borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          ElevatedButton(
                            onPressed: _isSubmitting ? null : () => _handleCreateCollection(controller),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.black38,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              ),
                              minimumSize: Size(72.w, 48.h),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    width: 18.w,
                                    height: 18.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 4.w),
                          IconButton(
                            icon: Icon(Icons.close, size: 20, color: AppColors.textMuted),
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            onPressed: () => setState(() => _isCreating = false),
                          ),
                        ],
                      )
                    : InkWell(
                        onTap: () => setState(() => _isCreating = true),
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36.w,
                                height: 36.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                ),
                                child: Icon(Icons.add, color: AppColors.surface, size: 20),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  'Create New Collection',
                                  style: AppTextStyles.bodyMediumBold.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              // Existing Collections List
              Flexible(
                child: Obx(() {
                  final collections = controller.collections;
                  if (collections.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.h),
                      child: Center(
                        child: Text(
                          'No collections yet. Create one above!',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    itemCount: collections.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, idx) {
                      final col = collections[idx];
                      return Obx(() {
                        final isSaved = controller.isItemInCollection(col.id, widget.itemId);
                        return InkWell(
                          onTap: () async {
                            final wasSaved = controller.isItemInCollection(col.id, widget.itemId);
                            await controller.toggleSaveItem(
                              collectionId: col.id,
                              itemId: widget.itemId,
                              imageUrl: widget.imageUrl,
                            );
                            Get.snackbar(
                              wasSaved ? 'Removed from Collection' : 'Saved to Collection',
                              wasSaved ? 'Unsaved from "${col.name}"' : 'Saved to "${col.name}"',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppColors.surface,
                              colorText: AppColors.textPrimary,
                              margin: EdgeInsets.all(16.w),
                              duration: const Duration(seconds: 2),
                              icon: Icon(
                                wasSaved ? Icons.bookmark_remove_outlined : Icons.bookmark_added_rounded,
                                color: wasSaved ? AppColors.textMuted : AppColors.accentSuccess,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          child: Container(
                            constraints: const BoxConstraints(minHeight: 56),
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSaved ? AppColors.surfaceLight : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                              border: Border.all(
                                color: isSaved ? AppColors.primary : AppColors.border,
                                width: isSaved ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                // Folder thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                  child: Container(
                                    width: 44.w,
                                    height: 44.h,
                                    color: AppColors.surfaceLight,
                                    child: col.coverImageUrl != null && col.coverImageUrl!.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: col.coverImageUrl!,
                                            fit: BoxFit.cover,
                                            errorWidget: (_, __, ___) => Icon(
                                              Icons.folder_outlined,
                                              color: AppColors.textMuted,
                                            ),
                                          )
                                        : Icon(
                                            Icons.folder_outlined,
                                            color: AppColors.textMuted,
                                          ),
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                // Folder details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        col.name,
                                        style: AppTextStyles.bodyMediumBold.copyWith(
                                          color: AppColors.textPrimary,
                                          fontSize: 14.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        isSaved ? 'Saved • Tap to remove' : '${col.itemCount} items',
                                        style: AppTextStyles.caption.copyWith(
                                          color: isSaved ? AppColors.primary : AppColors.textMuted,
                                          fontSize: 12.sp,
                                          fontWeight: isSaved ? FontWeight.w600 : FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Selection indicator
                                Container(
                                  width: 28.w,
                                  height: 28.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSaved ? AppColors.primary : Colors.transparent,
                                    border: Border.all(
                                      color: isSaved ? AppColors.primary : AppColors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSaved
                                      ? Icon(
                                          Icons.check,
                                          color: AppColors.surface,
                                          size: 16,
                                        )
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      });
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
