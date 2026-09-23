import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'tool_result_preview_sheet.dart';

class AiExpandSheet extends StatefulWidget {
  const AiExpandSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiExpandSheet(),
    );
  }

  @override
  State<AiExpandSheet> createState() => _AiExpandSheetState();
}

class _AiExpandSheetState extends State<AiExpandSheet> {
  final ToolsController controller = Get.find<ToolsController>();
  String? _selectedImagePath;
  String _selectedRatio = '16:9';
  String _selectedQuality = '1k'; // '1k', '2k'

  final List<String> _ratios = [
    '1:1', '3:4', '4:3', '9:16', '16:9', '2:3', '3:2', '2:1', '1:2'
  ];

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
    final creditCost = _selectedQuality == '1k' ? 10 : 14;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 16.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Expand',
                  style: AppTextStyles.h2.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Divider(height: 1.h, color: AppColors.border),

          // Scrollable Options
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                // 1. Upload Section
                _buildUploadSection(),
                SizedBox(height: 16.h),

                // 2. Target Ratio Grid
                _buildTargetRatioGrid(),
                SizedBox(height: 16.h),

                // 3. Canvas Placement View
                _buildCanvasPreview(),
                SizedBox(height: 16.h),

                // 4. Choose Quality
                _buildQualitySelector(),
                SizedBox(height: 16.h),
              ],
            ),
          ),

          // Bottom Action Button
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Obx(() {
              final isProcessing = controller.isProcessing.value;
              return SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isProcessing ? null : _handleExpand,
                  child: isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 18.w,
                              height: 18.w,
                              child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              controller.processingMessage.value.isNotEmpty
                                  ? controller.processingMessage.value
                                  : 'Expanding canvas...',
                              style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13.sp),
                            ),
                          ],
                        )
                      : Text(
                          'Expand image ✦ $creditCost',
                          style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 15.sp),
                        ),
                ),
              );
            }),
          ),
        ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.crop_original, size: 18.sp, color: AppColors.textPrimary),
              SizedBox(width: 8.w),
              RichText(
                text: TextSpan(
                  text: 'Upload an image ',
                  style: AppTextStyles.bodySmallBold.copyWith(color: AppColors.textPrimary),
                  children: [
                    TextSpan(text: '*', style: TextStyle(color: Colors.red, fontSize: 13.sp)),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.add_circle, color: AppColors.primary, size: 24.sp),
            onPressed: () => _showPickerSheet(),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetRatioGrid() {
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
          Text('Target ratio', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: _ratios.map((r) {
              final isSel = _selectedRatio == r;
              return GestureDetector(
                onTap: () => setState(() => _selectedRatio = r),
                child: Container(
                  width: 96.w,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.surface : AppColors.background,
                    borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border,
                      width: isSel ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.crop_square_outlined, size: 14.sp, color: isSel ? AppColors.primary : AppColors.textSecondary),
                      SizedBox(width: 6.w),
                      Text(
                        r,
                        style: AppTextStyles.captionBold.copyWith(
                          color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCanvasPreview() {
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
              Text('Canvas Preview', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => setState(() => _selectedImagePath = null),
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 14.sp, color: AppColors.textSecondary),
                    SizedBox(width: 4.w),
                    Text('Reset', style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Container(
            height: 160.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: _selectedImagePath != null
                ? Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      child: _selectedImagePath!.startsWith('http')
                          ? CachedNetworkImage(imageUrl: _selectedImagePath!, fit: BoxFit.contain)
                          : Image.file(File(_selectedImagePath!), fit: BoxFit.contain),
                    ),
                  )
                : Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        'Upload a photo to start placing it on canvas.\nGenerative outpaint fills the canvas seamlessly.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySelector() {
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
          Text('Choose quality', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(child: _buildQualityOption('1k', 'Fast 1K', '✦ 10 per')),
              SizedBox(width: 12.w),
              Expanded(child: _buildQualityOption('2k', 'HD 2K', '✦ 14 per')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityOption(String qualityKey, String title, String costLabel) {
    final isSelected = _selectedQuality == qualityKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedQuality = qualityKey),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.background,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
            Text(costLabel, style: AppTextStyles.captionXs.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleExpand() async {
    if (_selectedImagePath == null) {
      Get.snackbar('Image Required', 'Please upload a photo to expand.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    final outUrl = await controller.runAiExpand(
      path: _selectedImagePath!,
      targetRatio: _selectedRatio,
      quality: _selectedQuality,
    );

    if (outUrl != null && mounted) {
      Navigator.of(context).pop();
      ToolResultPreviewSheet.show(
        context: context,
        title: 'AI Expand',
        resultImageUrl: outUrl,
        originalImageUrl: _selectedImagePath,
        creditsUsed: _selectedQuality == '1k' ? 10.0 : 14.0,
        badgeText: 'Target Ratio: $_selectedRatio • $_selectedQuality',
        enableBeforeAfter: false,
      );
    }
  }
}
