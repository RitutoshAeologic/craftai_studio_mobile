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

class ProductDetailSheet extends StatefulWidget {
  const ProductDetailSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProductDetailSheet(),
    );
  }

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  final ToolsController controller = Get.find<ToolsController>();
  final TextEditingController _nameCtrl = TextEditingController();
  String? _selectedImagePath;
  String _selectedRatio = '4:5';
  String _selectedLanguage = 'Auto (match my input)';

  final List<String> _ratios = ['4:5', '1:1', '16:9', '9:16', 'Auto'];
  final List<String> _languages = ['Auto (match my input)', 'English', 'Spanish', 'German', 'Japanese'];

  @override
  void dispose() {
    _nameCtrl.dispose();
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
                Expanded(
                  child: Text(
                    'Product Detail Images',
                    style: AppTextStyles.h2.copyWith(fontSize: 18.sp, fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
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

          // Scrollable Form
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                Text('Set up the basics', style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
                SizedBox(height: 2.h),
                Text('Upload your product, pick size and language', style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
                SizedBox(height: 14.h),

                // 1. Upload Product Image
                _buildUploadSection(),
                SizedBox(height: 14.h),

                // 2. Product Name Field
                _buildNameField(),
                SizedBox(height: 14.h),

                // 3. Size / Ratio Dropdown
                _buildRatioDropdown(),
                SizedBox(height: 14.h),

                // 4. Detail Copy Language Dropdown
                _buildLanguageDropdown(),
                SizedBox(height: 16.h),
              ],
            ),
          ),

          // Bottom Button
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
                  onPressed: isProcessing ? null : _handleGenerateListing,
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
                                  : 'Generating listing...',
                              style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13.sp),
                            ),
                          ],
                        )
                      : Text(
                          'Generate Listing Set ✦ 10',
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
                  Icon(Icons.inventory_2_outlined, size: 18.sp, color: AppColors.textPrimary),
                  SizedBox(width: 8.w),
                  RichText(
                    text: TextSpan(
                      text: 'Upload Product Image ',
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

  Widget _buildNameField() {
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
              Text('Product Name', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
              Text('Optional', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
            ],
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _nameCtrl,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'e.g. Solid Wood Rattan Folding Chair',
              hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
          ),
        ],
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
          Text('Size / ratio', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
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

  Widget _buildLanguageDropdown() {
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
          Text('Detail Copy Language', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 8.h),
          DropdownButtonFormField<String>(
            value: _selectedLanguage,
            decoration: InputDecoration(
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            ),
            items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l, style: AppTextStyles.bodySmall))).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedLanguage = val);
            },
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

  Future<void> _handleGenerateListing() async {
    if (_selectedImagePath == null) {
      Get.snackbar('Image Required', 'Please upload a product photo.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    final prodName = _nameCtrl.text.trim().isNotEmpty ? _nameCtrl.text.trim() : 'Commercial Product';
    final outUrl = await controller.runProductDetail(
      path: _selectedImagePath!,
      productName: prodName,
      aspectRatio: _selectedRatio,
      language: _selectedLanguage,
    );

    if (outUrl != null && mounted) {
      Navigator.of(context).pop();
      ToolResultPreviewSheet.show(
        context: context,
        title: 'Product Listing Images',
        resultImageUrl: outUrl,
        originalImageUrl: _selectedImagePath,
        creditsUsed: 10.0,
        badgeText: 'Product: $prodName • $_selectedRatio',
        enableBeforeAfter: false,
      );
    }
  }
}
