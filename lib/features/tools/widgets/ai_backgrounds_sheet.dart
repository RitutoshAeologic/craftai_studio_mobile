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
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';

class AiBackgroundsSheet extends StatefulWidget {
  const AiBackgroundsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AiBackgroundsSheet(),
    );
  }

  @override
  State<AiBackgroundsSheet> createState() => _AiBackgroundsSheetState();
}

class _AiBackgroundsSheetState extends State<AiBackgroundsSheet> {
  final ToolsController controller = Get.find<ToolsController>();
  String? _selectedImagePath;
  String _selectedMode = 'smart'; // 'pure_white', 'smart', 'custom'
  String _selectedRatio = 'Auto';
  String _selectedQuality = '1k'; // '1k', '2k'
  final TextEditingController _customBackdropCtrl = TextEditingController();

  final List<String> _ratios = ['Auto', '1:1', '4:5', '9:16', '16:9'];

  @override
  void dispose() {
    _customBackdropCtrl.dispose();
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
    final isPureWhite = _selectedMode == 'pure_white';
    final creditCost = isPureWhite ? 0 : (_selectedQuality == '1k' ? 10 : 14);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 12.h, 16.w, 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Backgrounds',
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

                // 2. Choose a Background (Segmented Control)
                _buildModeSelector(),
                SizedBox(height: 16.h),

                // 3. Custom Backdrop Input (if custom selected)
                if (_selectedMode == 'custom') ...[
                  TextField(
                    controller: _customBackdropCtrl,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'e.g. Modern marble podium with sunlight',
                      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],

                // 4. Output Ratio Dropdown
                _buildRatioDropdown(),
                SizedBox(height: 16.h),

                // 5. Choose Quality
                if (!isPureWhite) ...[
                  _buildQualitySelector(),
                  SizedBox(height: 16.h),
                ],
              ],
            ),
          ),

          // Bottom Fixed Action Button
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
                  onPressed: isProcessing ? null : _handleReplaceBackground,
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
                                  : 'Processing...',
                              style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13.sp),
                            ),
                          ],
                        )
                      : Text(
                          isPureWhite ? 'Replace background (Free)' : 'Replace background ✦ $creditCost',
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.photo_outlined, size: 18.sp, color: AppColors.textPrimary),
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
          if (_selectedImagePath != null) ...[
            SizedBox(height: 10.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              child: SizedBox(
                height: 120.h,
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

  Widget _buildModeSelector() {
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
          Text('Choose a background', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
            ),
            child: Row(
              children: [
                _buildModeTab('pure_white', 'Pure white'),
                _buildModeTab('smart', 'Smart'),
                _buildModeTab('custom', 'Custom'),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            _selectedMode == 'pure_white'
                ? 'Instant 100% white studio background with natural shadow (Zero Tokens / Free).'
                : _selectedMode == 'smart'
                    ? 'Smartly adds a background to white-background or transparent images and refines lighting.'
                    : 'Describe your custom desired background backdrop.',
            style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab(String modeKey, String label) {
    final isSelected = _selectedMode == modeKey;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedMode = modeKey),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTextStyles.captionBold.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatioDropdown() {
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
          Text('Output ratio', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: _selectedRatio,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            items: _ratios.map((r) => DropdownMenuItem(value: r, child: Text(r, style: AppTextStyles.bodySmall))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedRatio = val);
            },
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
      builder: (_) {
        final libCtrl = Get.isRegistered<LibraryController>() ? Get.find<LibraryController>() : null;
        return SafeArea(
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

  Future<void> _handleReplaceBackground() async {
    if (_selectedImagePath == null) {
      Get.snackbar('Image Required', 'Please upload a photo first.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    final outUrl = await controller.runAiBackground(
      path: _selectedImagePath!,
      mode: _selectedMode,
      customBackdrop: _customBackdropCtrl.text.trim().isNotEmpty ? _customBackdropCtrl.text.trim() : null,
      aspectRatio: _selectedRatio,
      quality: _selectedQuality,
    );

    if (outUrl != null && mounted) {
      Navigator.of(context).pop();
      ToolResultPreviewSheet.show(
        context: context,
        title: 'AI Backgrounds',
        resultImageUrl: outUrl,
        originalImageUrl: _selectedImagePath,
        creditsUsed: _selectedMode == 'pure_white' ? 0.0 : (_selectedQuality == '1k' ? 10.0 : 14.0),
        badgeText: 'Mode: ${_selectedMode == "pure_white" ? "Pure White" : _selectedMode.capitalizeFirst} • $_selectedRatio',
        enableBeforeAfter: true,
      );
    }
  }
}
