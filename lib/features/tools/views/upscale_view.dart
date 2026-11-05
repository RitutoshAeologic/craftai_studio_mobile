import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:craftai_studio_mobile/features/tools/widgets/tool_result_preview_sheet.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';

class UpscaleView extends StatefulWidget {
  final String? initialImagePath;

  const UpscaleView({super.key, this.initialImagePath});

  @override
  State<UpscaleView> createState() => _UpscaleViewState();
}

class _UpscaleViewState extends State<UpscaleView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  String? _selectedImagePath;
  int _selectedScale = 2;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.clearActiveSession();
      }
    });
    _selectedImagePath = widget.initialImagePath;
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
        _selectedImagePath = file.path;
      });
    }
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
              SizedBox(height: 12.h),
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

    HapticFeedback.heavyImpact();
    final outUrl = await controller.runUpscale(
      path: _selectedImagePath!,
      scaleFactor: _selectedScale,
    );

    if (outUrl != null && mounted) {
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
          'Upscale 4K',
          style: AppTextStyles.h2.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
            ),
            child: Text(
              '2 Cr',
              style: AppTextStyles.captionBold.copyWith(
                color: AppColors.primary,
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
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                children: [
                  // 1. Upload Section
                  _buildUploadSection(),
                  SizedBox(height: 16.h),

                  // 2. Scale Multiplier
                  _buildScaleSelector(),
                  SizedBox(height: 16.h),

                  // 3. Information & Benefits Card
                  _buildEnhancementCard(),
                ],
              ),
            ),

            // Bottom Action Button
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Obx(() {
                final isProcessing = controller.isProcessing.value;
                return ModernAiButton(
                  label: 'Upscale to 4K ✦ 2',
                  icon: Icon(Icons.hd, color: Colors.white, size: 18),
                  
                  isLoading: isProcessing,
                  loadingMessage: controller.processingMessage.value.isNotEmpty
                      ? controller.processingMessage.value
                      : 'Upscaling image...',
                  onPressed: isProcessing ? null : _handleUpscale,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Input photo', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
            if (_selectedImagePath != null)
              BouncyTap(
                onTap: () => setState(() => _selectedImagePath = null),
                child: Text('Clear', style: AppTextStyles.captionXs.copyWith(color: AppColors.accentError)),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        BouncyTap(
          onTap: _showPickerSheet,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              border: Border.all(
                color: _selectedImagePath != null ? AppColors.primary : AppColors.border,
                width: 1.2.w,
              ),
            ),
            child: _selectedImagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    child: _selectedImagePath!.startsWith('http')
                        ? CachedNetworkImage(
                            imageUrl: _selectedImagePath!,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(_selectedImagePath!),
                            fit: BoxFit.contain,
                          ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 28.sp, color: AppColors.primary),
                      SizedBox(height: 6.h),
                      Text('Upload photo to sharpen & enlarge', style: AppTextStyles.bodySmallBold),
                      SizedBox(height: 2.h),
                      Text('Enhances blurry, small, or low-res images', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildScaleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resolution multiplier', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildScaleOption(2, '2X Super HD', 'Double pixel density, 2K output'),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildScaleOption(4, '4X Master Ultra', 'Quadruple pixels, 4K print ready'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScaleOption(int scale, String title, String subtitle) {
    final isSel = _selectedScale == scale;
    return BouncyTap(
      onTap: () => setState(() => _selectedScale = scale),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.border,
            width: isSel ? 1.5.w : 1.0.w,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.captionBold.copyWith(
                      color: isSel ? AppColors.primary : AppColors.textPrimary,
                      fontSize: 12.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  isSel ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 16.sp,
                  color: isSel ? AppColors.primary : AppColors.textTertiary,
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              subtitle,
              style: AppTextStyles.captionXs.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancementCard() {
    return Container(
      padding: EdgeInsets.all(14.r),
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
              Icon(Icons.auto_awesome, size: 16.sp, color: AppColors.primary),
              SizedBox(width: 6.w),
              Text(
                'Sub-pixel Neural Reconstruction',
                style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Uses Real-ESRGAN deep residual networks to reconstruct lost high-frequency textures, eyelashes, fabric weaves, and sharp typography without blurry bicubic interpolation.',
            style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary, height: 1.35),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              Icon(Icons.verified, size: 14.sp, color: AppColors.accentSuccess),
              SizedBox(width: 4.w),
              Text('Print & Wallpaper Ready', style: AppTextStyles.captionXs.copyWith(color: AppColors.accentSuccess, fontWeight: FontWeight.bold)),
              SizedBox(width: 12.w),
              Icon(Icons.speed, size: 14.sp, color: AppColors.primary),
              SizedBox(width: 4.w),
              Text('~3s Processing', style: AppTextStyles.captionXs.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
