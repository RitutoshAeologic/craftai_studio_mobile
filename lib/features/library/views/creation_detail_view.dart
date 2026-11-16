import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/library/widgets/download_paywall_sheet.dart';
import 'package:craftai_studio_mobile/features/library/widgets/publish_creation_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_image_edit_actions_sheet.dart';
import '../../../shared/widgets/interactions/bouncy_tap.dart';
import '../../../shared/widgets/image/zoomable_image_lightbox.dart';

/// [CreationDetailView] renders the full-screen MeiGen image detail screen.
/// Features:
/// - Hero high-res preview
/// - Top bar: `<` Back & `+ Publish`
/// - Actions row: Like, Download 4K, Copy Prompt, More options
/// - Creator info & expandable prompt text
/// - Floating bottom action button: `✏️ Edit image`
class CreationDetailView extends StatefulWidget {
  final JobModel job;

  const CreationDetailView({super.key, required this.job});

  @override
  State<CreationDetailView> createState() => _CreationDetailViewState();
}

class _CreationDetailViewState extends State<CreationDetailView> {
  bool _isLiked = false;
  int _likeCount = 12;
  bool _isPromptExpanded = false;

  bool get _isDownloadUnlocked {
    if (Get.isRegistered<LibraryController>()) {
      final found = Get.find<LibraryController>().myCreations.firstWhereOrNull((j) => j.jobId == widget.job.jobId);
      if (found != null) return found.isDownloadUnlocked;
    }
    return widget.job.isDownloadUnlocked;
  }

  void _openDownloadPaywall(BuildContext context) {
    final currentJob = (Get.isRegistered<LibraryController>())
        ? (Get.find<LibraryController>().myCreations.firstWhereOrNull((j) => j.jobId == widget.job.jobId) ?? widget.job)
        : widget.job;
    Get.bottomSheet(
      DownloadPaywallSheet(job: currentJob),
      isScrollControlled: true,
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
    });
  }

  void _copyPrompt() {
    Clipboard.setData(ClipboardData(text: widget.job.prompt));
    Get.snackbar(
      'Prompt Copied! 📋',
      'Prompt copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      duration: const Duration(seconds: 2),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    bool isDeleting = false;
    Get.dialog(
      StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.all(22.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.90),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.95),
                      width: 1.2.w,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 28.r,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.06),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.border.withValues(alpha: 0.6),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(Icons.delete_outline_rounded, color: Colors.black, size: 28.sp),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Delete Creation?',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'This will permanently delete this image from your cloud library and Supabase storage. This action cannot be undone.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: isDeleting ? null : () => Navigator.of(dialogContext).pop(),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.50),
                                side: BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: Text('Cancel', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () async {
                                      setDialogState(() {
                                        isDeleting = true;
                                      });
                                      final libCtrl = Get.isRegistered<LibraryController>()
                                          ? Get.find<LibraryController>()
                                          : Get.put(LibraryController());
                                      
                                      // Perform deletion without premature snackbar
                                      final success = await libCtrl.deleteCreation(widget.job, showSnackbar: false);
                                      if (!success) {
                                        setDialogState(() {
                                          isDeleting = false;
                                        });
                                        if (Get.overlayContext != null && !Get.testMode) {
                                          Get.snackbar(
                                            'Delete Failed',
                                            'Could not delete image. Please check your network and try again.',
                                            snackPosition: SnackPosition.BOTTOM,
                                            backgroundColor: AppColors.surface,
                                            colorText: AppColors.accentWarning,
                                            icon: Icon(Icons.error_outline_rounded, color: AppColors.accentWarning),
                                            margin: EdgeInsets.all(16.w),
                                            borderRadius: 12.r,
                                            duration: const Duration(seconds: 3),
                                          );
                                        }
                                        return;
                                      }
                                      
                                      // Close confirmation dialog
                                      if (dialogContext.mounted) {
                                        Navigator.of(dialogContext).pop();
                                      }
                                      
                                      // Pop back from CreationDetailView immediately to Library list view
                                      if (context.mounted) {
                                        Navigator.of(context).pop(true);
                                      }
                                      
                                      // Display prominent success toast on the Library list screen
                                      if (Get.overlayContext != null && !Get.testMode) {
                                        Get.snackbar(
                                          'Image Deleted 🗑️',
                                          'Image successfully removed from your library and cloud storage.',
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: AppColors.surface,
                                          colorText: AppColors.textPrimary,
                                          icon: Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess),
                                          margin: EdgeInsets.all(16.w),
                                          borderRadius: 12.r,
                                          duration: const Duration(seconds: 3),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.black.withValues(alpha: 0.6),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                padding: EdgeInsets.symmetric(vertical: 12.h),
                              ),
                              child: isDeleting
                                  ? SizedBox(
                                      width: 18.w,
                                      height: 18.w,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                                      ),
                                    )
                                  : Text('Delete', style: AppTextStyles.captionBold.copyWith(color: AppColors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: Center(
            child: IconButton(
              onPressed: () => Get.back(),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, size: 16.sp, color: AppColors.textPrimary),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => PublishCreationSheet.show(context, widget.job),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.textPrimary,
                  elevation: 0,
                  side: BorderSide(color: AppColors.border),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusRound)),
                ),
                icon: Icon(Icons.add, size: 16.sp, color: AppColors.textPrimary),
                label: Text(
                  'Publish',
                  style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 90.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),

                  // Hero Image Display with Pinch & Zoom Lightbox trigger
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        final effectiveUrl = widget.job.previewUrl.isNotEmpty &&
                                widget.job.previewUrl.startsWith('http')
                            ? widget.job.previewUrl
                            : 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop';
                        ZoomableImageLightbox.show(
                          context: context,
                          imageUrl: effectiveUrl,
                          heroTag: 'creation_detail_hero_${widget.job.jobId}',
                          title: widget.job.prompt.isNotEmpty
                              ? widget.job.prompt
                              : 'Creation Artwork',
                          subtitle: widget.job.toolApplied,
                          aspectRatioStr: widget.job.aspectRatio,
                          onDownload: () => _openDownloadPaywall(context),
                        );
                      },
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.r),
                            child: Container(
                              constraints: BoxConstraints(
                                minHeight: 220.h,
                                maxHeight: 450.h,
                              ),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(
                                child: Hero(
                                  tag: 'creation_detail_hero_${widget.job.jobId}',
                                  child: CachedNetworkImage(
                                    imageUrl: widget.job.previewUrl.isNotEmpty &&
                                            widget.job.previewUrl.startsWith('http')
                                        ? widget.job.previewUrl
                                        : 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop',
                                    fit: BoxFit.contain,
                                    placeholder: (_, __) =>
                                        Container(color: AppColors.surfaceLight),
                                    errorWidget: (_, __, ___) => Container(
                                      color: AppColors.surfaceLight,
                                      child: Center(
                                          child: Icon(Icons.broken_image,
                                              color: AppColors.textMuted)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Subtle zoom affordance badge (Bottom-right)
                          Positioned(
                            bottom: 10.h,
                            right: 10.w,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius:
                                    BorderRadius.circular(AppDimens.radiusRound),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                  width: 1.w,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.zoom_in_rounded,
                                      size: 14.sp, color: Colors.white),
                                  SizedBox(width: 4.w),
                                  Text(
                                    'Pinch & Zoom',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Unified Responsive Actions Toolbar
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Like Action
                        BouncyTap(
                          onTap: _toggleLike,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: _isLiked ? AppColors.accentError : AppColors.textPrimary,
                                  size: 18.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '$_likeCount',
                                  style: AppTextStyles.captionBold.copyWith(
                                    color: _isLiked ? AppColors.accentError : AppColors.textPrimary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1.w, height: 18.h, color: AppColors.border),

                        // Copy Prompt Action
                        BouncyTap(
                          onTap: _copyPrompt,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.copy_rounded, size: 16.sp, color: AppColors.textPrimary),
                                SizedBox(width: 4.w),
                                Text(
                                  'Copy',
                                  style: AppTextStyles.captionBold.copyWith(
                                    color: AppColors.textPrimary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1.w, height: 18.h, color: AppColors.border),

                        // 4K Download Action
                        BouncyTap(
                          onTap: () => _openDownloadPaywall(context),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isDownloadUnlocked ? Icons.download_done_rounded : Icons.file_download_outlined,
                                  size: 18.sp,
                                  color: _isDownloadUnlocked ? AppColors.accentSuccess : AppColors.textPrimary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '4K',
                                  style: AppTextStyles.captionBold.copyWith(
                                    color: _isDownloadUnlocked ? AppColors.accentSuccess : AppColors.textPrimary,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1.w, height: 18.h, color: AppColors.border),

                        // Delete Action
                        Tooltip(
                          message: 'Delete Creation',
                          child: BouncyTap(
                            onTap: () => _showDeleteConfirmation(context),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 18.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: AppColors.border, height: 16.h),

                  // Creator Info & Prompt
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14.r,
                              backgroundColor: AppColors.surfaceLight,
                              child: Icon(Icons.person_rounded, size: 16.sp, color: AppColors.textSecondary),
                            ),
                            SizedBox(width: 10.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You',
                                  style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                                ),
                                Text(
                                  'Cloud Saved',
                                  style: AppTextStyles.captionXs.copyWith(
                                    color: AppColors.accentSuccess,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 10.h),

                        // Prompt with More/Less
                        GestureDetector(
                          onTap: () => setState(() => _isPromptExpanded = !_isPromptExpanded),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 13.sp, height: 1.4),
                              children: [
                                TextSpan(
                                  text: _isPromptExpanded || widget.job.prompt.length <= 90
                                      ? widget.job.prompt
                                      : '${widget.job.prompt.substring(0, 90)}...',
                                ),
                                if (widget.job.prompt.length > 90)
                                  TextSpan(
                                    text: _isPromptExpanded ? ' Less' : ' More',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
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

            // Floating Bottom Button: "✏️ Edit image"
            Positioned(
              bottom: 16.h,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => StudioImageEditActionsSheet.show(context, widget.job),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        side: BorderSide(color: AppColors.border),
                      ),
                    ),
                    icon: Icon(Icons.edit_outlined, size: 16.sp, color: AppColors.primary),
                    label: Text(
                      'Edit image',
                      style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
