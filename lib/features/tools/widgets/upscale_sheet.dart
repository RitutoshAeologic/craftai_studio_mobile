import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/shared/widgets/interactions/bouncy_tap.dart';
import 'package:craftai_studio_mobile/shared/widgets/glass/modern_ai_button.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'tool_result_preview_sheet.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';

class UpscaleSheet extends StatefulWidget {
  const UpscaleSheet({super.key});

  static void show(BuildContext context) {
    if (Get.isRegistered<ToolsController>()) {
      Get.find<ToolsController>().clearActiveSession();
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UpscaleSheet(),
    );
  }

  @override
  State<UpscaleSheet> createState() => _UpscaleSheetState();
}

class _UpscaleSheetState extends State<UpscaleSheet> {
  final ToolsController controller = Get.find<ToolsController>();
  String? _selectedImagePath;
  int _selectedScale = 2;

  @override
  void initState() {
    super.initState();
    controller.clearActiveSession();
  }

  @override
  void dispose() {
    controller.clearActiveSession();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await controller.pickImage(source);
    if (file != null && mounted) {
      setState(() {
        _selectedImagePath = file.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.82,
          decoration: BoxDecoration(
            color: AppColors.glassDarkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.2.w),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              SizedBox(height: 10.h),
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 16.w, 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Upscale 4K',
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    BouncyTap(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.60),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18.sp, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.h, color: AppColors.glassBorderSubtle),

              // Scrollable Form
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  children: [
                    Text(
                      'Enlarge images & videos in HD',
                      style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 14.h),

                    // Upload Section
                    _buildUploadSection(),
                    SizedBox(height: 16.h),

                    // Scale Selection
                    _buildScaleSelector(),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),

              // Bottom Action Button
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                decoration: BoxDecoration(
                  color: AppColors.glassDarkSurface,
                  border: Border(top: BorderSide(color: AppColors.glassBorderSubtle)),
                ),
                child: Obx(() {
                  final isProcessing = controller.isProcessing.value;
                  return ModernAiButton(
                    label: 'Upscale to 4K ✦ 2',
                    isLoading: isProcessing,
                    loadingMessage: controller.processingMessage.value.isNotEmpty
                        ? controller.processingMessage.value
                        : 'Enhancing resolution...',
                    onPressed: isProcessing ? null : _handleUpscale,
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.hd_outlined, size: 18.sp, color: AppColors.textPrimary),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: RichText(
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          text: 'Upload photo to upscale ',
                          style: AppTextStyles.bodySmallBold.copyWith(color: AppColors.textPrimary),
                          children: [
                            TextSpan(text: '*', style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: AppColors.primary, size: 24.sp),
                onPressed: () => _showPickerSheet(),
              ),
            ],
          ),
          if (_selectedImagePath != null) ...[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: SizedBox(
                height: 140.h,
                width: double.infinity,
                child: _selectedImagePath!.startsWith('http')
                    ? CachedNetworkImage(imageUrl: _selectedImagePath!, fit: BoxFit.contain)
                    : Image.file(File(_selectedImagePath!), fit: BoxFit.contain),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScaleSelector() {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resolution multiplier', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedScale = 2),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: _selectedScale == 2 ? AppColors.surface : AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(
                        color: _selectedScale == 2 ? AppColors.primary : AppColors.border,
                        width: _selectedScale == 2 ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text('2X Super HD', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                        SizedBox(height: 2.h),
                        Text('Up to 2048px', style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedScale = 4),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: _selectedScale == 4 ? AppColors.surface : AppColors.background,
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      border: Border.all(
                        color: _selectedScale == 4 ? AppColors.primary : AppColors.border,
                        width: _selectedScale == 4 ? 1.5 : 1.0,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text('4X Master Ultra', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                        SizedBox(height: 2.h),
                        Text('Up to 4096px', style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg))),
      builder: (_) {
        final libCtrl = Get.isRegistered<LibraryController>() ? Get.find<LibraryController>() : null;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Take a Photo'),
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
                    child: Text('Recent Creations', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
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
                          setState(() => _selectedImagePath = job.previewUrl);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          child: CachedNetworkImage(imageUrl: job.previewUrl, width: 60.w, height: 60.h, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleUpscale() async {
    if (_selectedImagePath == null) {
      Get.snackbar('Image Required', 'Please upload a photo first.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    final outUrl = await controller.runUpscale(
      path: _selectedImagePath!,
      scaleFactor: _selectedScale,
    );

    if (outUrl != null && mounted) {
      Navigator.of(context).pop();
      ToolResultPreviewSheet.show(
        context: context,
        title: '4K Super-Resolution',
        resultImageUrl: outUrl,
        originalImageUrl: _selectedImagePath,
        creditsUsed: 2.0,
        badgeText: 'Scale: ${_selectedScale}X • Ultra HD',
        enableBeforeAfter: true,
      );
    }
  }
}
