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
import 'package:craftai_studio_mobile/features/library/widgets/publish_creation_sheet.dart';
import 'package:craftai_studio_mobile/features/library/widgets/download_paywall_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_image_edit_actions_sheet.dart';

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
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentError.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.delete_forever_rounded, color: AppColors.accentError, size: 28.sp),
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
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
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
                                  await libCtrl.deleteCreation(widget.job, showSnackbar: false);
                                  
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
                                      icon: const Icon(Icons.check_circle_rounded, color: AppColors.accentSuccess),
                                      margin: EdgeInsets.all(16.w),
                                      borderRadius: 12.r,
                                      duration: const Duration(seconds: 3),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentError,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: AppColors.accentError.withValues(alpha: 0.6),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                          ),
                          child: isDeleting
                              ? SizedBox(
                                  width: 18.w,
                                  height: 18.w,
                                  child: const CircularProgressIndicator(
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
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable Content
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 90.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Navigation Bar
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        IconButton(
                          onPressed: () => Get.back(),
                          icon: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16.sp, color: AppColors.textPrimary),
                          ),
                        ),

                        // + Publish Button
                        ElevatedButton.icon(
                          onPressed: () => PublishCreationSheet.show(context, widget.job),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            elevation: 0,
                            side: const BorderSide(color: AppColors.border),
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusRound)),
                          ),
                          icon: Icon(Icons.add, size: 16.sp, color: AppColors.textPrimary),
                          label: Text(
                            'Publish',
                            style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 8.h),

                  // Hero Image Display
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: AspectRatio(
                        aspectRatio: 0.85,
                        child: CachedNetworkImage(
                          imageUrl: widget.job.previewUrl.isNotEmpty && widget.job.previewUrl.startsWith('http')
                              ? widget.job.previewUrl
                              : 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.surfaceLight),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceLight,
                            child: const Center(child: Icon(Icons.broken_image, color: AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 12.h),

                  // Actions Row: Like, Download, Copy, More
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4.w,
                      runSpacing: 4.h,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Like Button
                            IconButton(
                              onPressed: _toggleLike,
                              icon: Icon(
                                _isLiked ? Icons.favorite : Icons.favorite_border,
                                color: _isLiked ? AppColors.accentError : AppColors.textPrimary,
                                size: 22.sp,
                              ),
                            ),
                            Text(
                              '$_likeCount',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                            SizedBox(width: 8.w),

                            // Download Button
                            IconButton(
                              onPressed: () => Get.bottomSheet(DownloadPaywallSheet(job: widget.job)),
                              icon: Icon(Icons.download_rounded, size: 22.sp, color: AppColors.textPrimary),
                            ),
                            SizedBox(width: 4.w),

                            // Copy Button
                            TextButton.icon(
                              onPressed: _copyPrompt,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                              ),
                              icon: Icon(Icons.copy_rounded, size: 16.sp, color: AppColors.textPrimary),
                              label: Text(
                                'Copy',
                                style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Delete button
                            IconButton(
                              onPressed: () => _showDeleteConfirmation(context),
                              icon: Icon(Icons.delete_outline_rounded, size: 22.sp, color: AppColors.accentError),
                              tooltip: 'Delete Creation',
                            ),

                            // More options
                            IconButton(
                              onPressed: () => StudioImageEditActionsSheet.show(context, widget.job),
                              icon: Icon(Icons.more_vert_rounded, size: 22.sp, color: AppColors.textPrimary),
                            ),
                          ],
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
                                  widget.job.isDownloadUnlocked ? 'Unlocked (4K Ready)' : 'Cloud Saved (Free)',
                                  style: AppTextStyles.captionXs.copyWith(
                                    color: widget.job.isDownloadUnlocked ? AppColors.accentSuccess : AppColors.textMuted,
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
                        side: const BorderSide(color: AppColors.border),
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
