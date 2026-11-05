import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_icons.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/shared/widgets/app_network_image.dart';
import 'package:craftai_studio_mobile/shared/widgets/interactions/bouncy_tap.dart';
import 'package:craftai_studio_mobile/shared/widgets/glass/modern_ai_button.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/tool_result_preview_sheet.dart';

class BackgroundRemoverView extends StatefulWidget {
  final String? initialImagePath;

  const BackgroundRemoverView({super.key, this.initialImagePath});

  @override
  State<BackgroundRemoverView> createState() => _BackgroundRemoverViewState();
}

class _BackgroundRemoverViewState extends State<BackgroundRemoverView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  String? _imagePath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.clearActiveSession();
      }
    });
    _imagePath = widget.initialImagePath;
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      controller.inputImagePath.value = _imagePath;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ToolsController>()) {
        controller.clearActiveSession();
      }
    });
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await controller.pickImage(source);
    if (file != null && mounted) {
      setState(() {
        _imagePath = file.path;
      });
      controller.inputImagePath.value = file.path;
      controller.resultImageUrl.value = null;
    }
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (_) {
        final libCtrl = Get.isRegistered<LibraryController>() ? Get.find<LibraryController>() : null;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8.h),
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary, size: 22.sp),
                title: Text('Choose from Gallery', style: AppTextStyles.bodyMediumBold),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary, size: 22.sp),
                title: Text('Take a Photo', style: AppTextStyles.bodyMediumBold),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (libCtrl != null && libCtrl.myCreations.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Recent Creations',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                SizedBox(
                  height: 70.h,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                    itemCount: libCtrl.myCreations.length.clamp(0, 10),
                    separatorBuilder: (_, __) => SizedBox(width: 8.w),
                    itemBuilder: (_, idx) {
                      final job = libCtrl.myCreations[idx];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _imagePath = job.previewUrl;
                          });
                          controller.inputImagePath.value = job.previewUrl;
                          controller.resultImageUrl.value = null;
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          child: CachedNetworkImage(
                            imageUrl: job.previewUrl,
                            width: 60.w,
                            height: 60.h,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              SizedBox(height: 12.h),
            ],
          ),
        );
      },
    );
  }

  Future<void> _executeRemoveBackground() async {
    final activePath = _imagePath ?? controller.inputImagePath.value;
    if (activePath == null || activePath.isEmpty) {
      Get.snackbar(
        'Photo Required 📷',
        'Please select a photo first.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
      return;
    }

    HapticFeedback.heavyImpact();
    await controller.runBackgroundRemoval(directPath: activePath);

    if (controller.resultImageUrl.value != null && mounted) {
      ToolResultPreviewSheet.show(
        context: context,
        title: 'Background Remover',
        resultImageUrl: controller.resultImageUrl.value!,
        originalImageUrl: activePath,
        creditsUsed: 0.0,
        badgeText: 'Zero-Token • U2-Net',
        enableBeforeAfter: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20.sp),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Remove Background',
          style: AppTextStyles.h2.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.accentSuccess.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.35)),
            ),
            child: Text(
              'FREE',
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.accentSuccess,
                fontSize: 10.sp,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description Card
                    Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.r),
                            decoration: BoxDecoration(
                              color: AppColors.accentSuccess.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(AppIcons.bgRemover, color: AppColors.accentSuccess, size: 20.sp),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Instant Transparent Cutout',
                                  style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Extract clean PNG cutouts with zero tokens using neural U2-Net',
                                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // Main Image Area
                    Obx(() {
                      final resultUrl = controller.resultImageUrl.value;
                      final activePath = _imagePath ?? controller.inputImagePath.value;

                      if (resultUrl != null) {
                        return _buildCutoutResultCard(resultUrl, activePath);
                      }

                      if (activePath != null && activePath.isNotEmpty) {
                        return _buildInputPreviewCard(activePath);
                      }

                      return _buildUploadPromptCard();
                    }),

                    SizedBox(height: 20.h),

                    // Feature highlights / Tips
                    Text('Tips for best results', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                    SizedBox(height: 8.h),
                    _buildTipRow(Icons.check_circle_outline, 'Clear contrast between foreground object and background'),
                    SizedBox(height: 6.h),
                    _buildTipRow(Icons.check_circle_outline, 'Ideal for products, portraits, pets, and studio items'),
                    SizedBox(height: 6.h),
                    _buildTipRow(Icons.check_circle_outline, 'Exported cutouts can be used in Studio as reference photos'),
                  ],
                ),
              ),
            ),

            // Bottom Action Button
            Obx(() {
              final isProcessing = controller.isProcessing.value;
              final hasImage = (_imagePath != null && _imagePath!.isNotEmpty) ||
                  controller.inputImagePath.value != null;
              final hasResult = controller.resultImageUrl.value != null;

              if (hasResult) {
                return Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _imagePath = null;
                            });
                            controller.clearActiveSession();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.border),
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                          ),
                          icon: Icon(Icons.refresh, size: 16.sp, color: AppColors.textSecondary),
                          label: Text('New Photo', style: AppTextStyles.bodySmallBold.copyWith(color: AppColors.textPrimary)),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final resultUrl = controller.resultImageUrl.value;
                            if (resultUrl != null) {
                              final studioCtrl = Get.find<StudioController>();
                              studioCtrl.referenceImages.clear();
                              studioCtrl.addReferenceImage(resultUrl);
                              Get.find<ShellController>().switchTab(1);
                              Get.snackbar(
                                'Cutout Injected! 🎨',
                                'Transparent cutout loaded as Studio reference photo.',
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: AppColors.surface,
                                colorText: AppColors.primary,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                          ),
                          icon: Icon(Icons.palette_outlined, size: 16.sp, color: Colors.white),
                          label: Text('Use in Studio', style: AppTextStyles.bodySmallBold.copyWith(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Padding(
                padding: EdgeInsets.all(16.r),
                child: ModernAiButton(
                  label: 'Remove Background (Free)',
                  icon: Icon(Icons.auto_fix_high, color: Colors.white, size: 18),
                  
                  isLoading: isProcessing,
                  loadingMessage: controller.processingMessage.value.isNotEmpty
                      ? controller.processingMessage.value
                      : 'Removing background...',
                  onPressed: (!hasImage || isProcessing) ? null : _executeRemoveBackground,
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14.sp, color: AppColors.accentSuccess),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(text, style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildUploadPromptCard() {
    return BouncyTap(
      onTap: _showImagePickerSheet,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 36.sp),
            ),
            SizedBox(height: 12.h),
            Text(
              'Select Photo to Cut Out',
              style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 15.sp),
            ),
            SizedBox(height: 4.h),
            Text(
              'Choose from Gallery, Camera, or Library creations',
              style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
            ),
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              ),
              child: Text(
                'Choose Photo',
                style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPreviewCard(String path) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
                child: SizedBox(
                  height: 240.h,
                  width: double.infinity,
                  child: path.startsWith('data:')
                      ? Image.memory(base64Decode(path.split(',').last), fit: BoxFit.contain)
                      : path.startsWith('http')
                          ? CachedNetworkImage(imageUrl: path, fit: BoxFit.contain)
                          : Image.file(File(path), fit: BoxFit.contain),
                ),
              ),
              Positioned(
                top: 10.h,
                right: 10.w,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _imagePath = null;
                    });
                    controller.clearActiveSession();
                  },
                  child: Container(
                    padding: EdgeInsets.all(6.r),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(Icons.close, color: AppColors.accentError, size: 16.sp),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.image_outlined, size: 16.sp, color: AppColors.textSecondary),
                    SizedBox(width: 6.w),
                    Text('Photo selected', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showImagePickerSheet,
                  icon: Icon(Icons.swap_horiz, size: 16.sp, color: AppColors.primary),
                  label: Text('Change', style: AppTextStyles.captionBold.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCutoutResultCard(String resultUrl, String? originalPath) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
            child: Container(
              height: 260.h,
              width: double.infinity,
              color: AppColors.surfaceLight,
              child: Stack(
                children: [
                  Center(
                    child: AppNetworkImage(
                      imageUrl: resultUrl,
                      fit: BoxFit.contain,
                      placeholder: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10.h,
                    left: 10.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Cutout Ready',
                        style: AppTextStyles.captionXs.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10.h,
                    right: 10.w,
                    child: BouncyTap(
                      onTap: () {
                        if (originalPath != null) {
                          ToolResultPreviewSheet.show(
                            context: context,
                            title: 'Background Remover',
                            resultImageUrl: resultUrl,
                            originalImageUrl: originalPath,
                            creditsUsed: 0.0,
                            badgeText: 'Zero-Token • U2-Net',
                            enableBeforeAfter: true,
                          );
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(4.r),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.compare, size: 14.sp, color: AppColors.textPrimary),
                            SizedBox(width: 4.w),
                            Text('Compare', style: AppTextStyles.captionXs.copyWith(color: AppColors.textPrimary)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transparent PNG format',
                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                ),
                TextButton(
                  onPressed: _showImagePickerSheet,
                  child: Text('Change Source Photo', style: AppTextStyles.captionBold.copyWith(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
