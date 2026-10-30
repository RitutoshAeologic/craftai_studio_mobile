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
import 'package:craftai_studio_mobile/shared/widgets/before_after_slider.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/tool_result_preview_sheet.dart';

class PhotoColorizerView extends StatefulWidget {
  final String? initialImagePath;

  const PhotoColorizerView({super.key, this.initialImagePath});

  @override
  State<PhotoColorizerView> createState() => _PhotoColorizerViewState();
}

class _PhotoColorizerViewState extends State<PhotoColorizerView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  String? _imagePath;
  String? _colorizedImageUrl;
  double _selectedSaturation = 1.2;

  final List<Map<String, dynamic>> _saturationPresets = const [
    {'value': 0.8, 'label': '0.8x Muted'},
    {'value': 1.0, 'label': '1.0x Natural'},
    {'value': 1.2, 'label': '1.2x Rich ★'},
    {'value': 1.4, 'label': '1.4x Vibrant'},
  ];

  @override
  void initState() {
    super.initState();
    controller.clearActiveSession();
    _imagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    controller.clearActiveSession();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await controller.pickImage(source);
    if (file != null) {
      setState(() {
        _imagePath = file.path;
        _colorizedImageUrl = null;
      });
    }
  }

  Future<void> _executeColorize() async {
    if (_imagePath == null || _imagePath!.isEmpty) {
      Get.snackbar('Photo Required 📷', 'Please select a black-and-white or historical photo first.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    HapticFeedback.heavyImpact();
    final outUrl = await controller.runPhotoColorize(
      path: _imagePath!,
      saturation: _selectedSaturation,
    );

    if (outUrl != null && mounted) {
      setState(() {
        _colorizedImageUrl = outUrl;
      });
      HapticFeedback.mediumImpact();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Vintage Photo Colorizer', style: AppTextStyles.h2.copyWith(fontSize: 18.sp)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Preview / Split Slider Viewport
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildMainViewer(),
              ),
            ),

            // Saturation & Controls Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Saturation Intensity',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        ),
                        child: Text(
                          'Zero-Token • Free',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.accentSuccess, fontSize: 10.sp),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 10.h),

                  // Saturation Preset Chips
                  SizedBox(
                    height: 36.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _saturationPresets.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, index) {
                        final preset = _saturationPresets[index];
                        final val = preset['value'] as double;
                        final isSelected = _selectedSaturation == val;
                        return ChoiceChip(
                          label: Text(preset['label'] as String),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _selectedSaturation = val;
                              });
                              // Auto re-render if already colorized
                              if (_colorizedImageUrl != null) {
                                _executeColorize();
                              }
                            }
                          },
                          backgroundColor: AppColors.surfaceLight,
                          selectedColor: AppColors.primary,
                          labelStyle: AppTextStyles.captionXs.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Primary CTA Button
                  Obx(() {
                    final isProcessing = controller.isProcessing.value;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : _executeColorize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                          ),
                        ),
                        icon: isProcessing
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.palette_outlined, size: 18.sp, color: Colors.white),
                        label: Text(
                          isProcessing ? controller.processingMessage.value : '🎨 RESTORE NATURAL COLORS',
                          style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainViewer() {
    if (_imagePath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48.sp, color: AppColors.textMuted),
            SizedBox(height: 12.h),
            Text('Select a black & white photo',
                style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
            SizedBox(height: 4.h),
            Text('Restore historical portraits, family archives, or vintage scans',
                style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
              ),
              icon: const Icon(Icons.add_photo_alternate, size: 16),
              label: const Text('Choose Photo'),
            ),
          ],
        ),
      );
    }

    if (_colorizedImageUrl != null) {
      return Column(
        children: [
          Expanded(
            child: BeforeAfterSlider(
              beforeImageUrl: _imagePath!,
              afterImageUrl: _colorizedImageUrl!,
              beforeLabel: 'ORIGINAL (B&W)',
              afterLabel: 'RESTORED (COLOR)',
              height: 450,
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Drag slider to compare transformation',
                    style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
                TextButton.icon(
                  onPressed: () {
                    ToolResultPreviewSheet.show(
                      context: context,
                      title: 'Vintage Photo Colorizer',
                      resultImageUrl: _colorizedImageUrl!,
                      originalImageUrl: _imagePath,
                      creditsUsed: 0.0,
                      badgeText: 'DDColor Neural Restorer',
                      enableBeforeAfter: true,
                    );
                  },
                  icon: Icon(Icons.open_in_full_rounded, size: 14.sp, color: AppColors.primary),
                  label: Text('Export Master', style: TextStyle(color: AppColors.primary, fontSize: 11.sp)),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        _imagePath!.startsWith('http')
            ? CachedNetworkImage(imageUrl: _imagePath!, fit: BoxFit.contain)
            : Image.file(File(_imagePath!), fit: BoxFit.contain),
        Positioned(
          bottom: 12.h,
          left: 12.w,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.filter_b_and_w, size: 12.sp, color: AppColors.textSecondary),
                SizedBox(width: 4.w),
                Text('Original Monochrome', style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

