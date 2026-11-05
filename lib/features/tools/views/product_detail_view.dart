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
import 'package:craftai_studio_mobile/features/tools/widgets/product_pack_preview_sheet.dart';

class ProductDetailView extends StatefulWidget {
  final bool isPackMode;
  final String? initialImagePath;

  const ProductDetailView({super.key, this.isPackMode = false, this.initialImagePath});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  final TextEditingController _nameCtrl = TextEditingController();
  late bool _isPackMode;
  String? _selectedImagePath;
  String _selectedRatio = '4:5';
  String _selectedLanguage = 'Auto (match my input)';

  final List<String> _ratios = ['4:5', '1:1', '16:9', '9:16', 'Auto'];
  final List<String> _languages = ['Auto (match my input)', 'English', 'Spanish', 'German', 'Japanese'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.clearActiveSession();
      }
    });
    _isPackMode = widget.isPackMode;
    _selectedImagePath = widget.initialImagePath;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
      builder: (_) => SafeArea(
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
            SizedBox(height: 12.h),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Product Name Required', 'Please provide a name or short title for the product.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    HapticFeedback.heavyImpact();

    if (_isPackMode) {
      final pack = await controller.runProductPack(
        productName: name,
        path: _selectedImagePath,
      );

      if (pack != null && mounted) {
        ProductPackPreviewSheet.show(
          context: context,
          productName: name,
          pack: pack,
        );
      }
    } else {
      final outUrl = await controller.runProductDetail(
        productName: name,
        path: _selectedImagePath,
        aspectRatio: _selectedRatio,
        language: _selectedLanguage,
      );

      if (outUrl != null && mounted) {
        ToolResultPreviewSheet.show(
          context: context,
          title: 'Product Detail Images',
          resultImageUrl: outUrl,
          originalImageUrl: _selectedImagePath,
          creditsUsed: 10.0,
          badgeText: '$name • $_selectedRatio',
          enableBeforeAfter: false,
        );
      }
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
          _isPackMode ? 'E-Commerce 4-Pack' : 'Product Detail Images',
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
              '10 Cr',
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
                  // 1. Pack Mode Selector Toggle
                  Text('Set up the basics', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(child: _buildModeTab(true, '📦 4-Pack (Shopify & Amazon)')),
                      SizedBox(width: 8.w),
                      Expanded(child: _buildModeTab(false, '🛍️ Single Staged Image')),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // 2. Product Name / Title Input
                  Text('Product Name / Title *', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _nameCtrl,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'e.g. Minimalist Ceramic Coffee Mug',
                      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textTertiary),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 3. Upload Reference Photo (Optional)
                  _buildUploadSection(),
                  SizedBox(height: 16.h),

                  // 4. Output Ratio
                  _buildRatioDropdown(),
                  SizedBox(height: 16.h),

                  // 5. Language
                  if (!_isPackMode) ...[
                    _buildLanguageDropdown(),
                    SizedBox(height: 16.h),
                  ],
                ],
              ),
            ),

            // Bottom Generate Button
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Obx(() {
                final isProcessing = controller.isProcessing.value;
                return ModernAiButton(
                  label: _isPackMode ? 'Generate 4-Pack ✦ 10' : 'Generate Listing Set ✦ 10',
                  icon: Icon(Icons.storefront, color: Colors.white, size: 18),
                  
                  isLoading: isProcessing,
                  loadingMessage: controller.processingMessage.value.isNotEmpty
                      ? controller.processingMessage.value
                      : (_isPackMode ? 'Generating 4-pack suite...' : 'Generating product shots...'),
                  onPressed: isProcessing ? null : _handleGenerate,
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab(bool isPack, String label) {
    final isSel = _isPackMode == isPack;
    return BouncyTap(
      onTap: () => setState(() => _isPackMode = isPack),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.border,
            width: isSel ? 1.5.w : 1.0.w,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.captionBold.copyWith(
              color: isSel ? AppColors.primary : AppColors.textSecondary,
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
          ),
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
            Text('Reference Photo (Optional)', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
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
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
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
                        ? CachedNetworkImage(imageUrl: _selectedImagePath!, fit: BoxFit.contain)
                        : Image.file(File(_selectedImagePath!), fit: BoxFit.contain),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 26.sp, color: AppColors.primary),
                      SizedBox(height: 6.h),
                      Text('Upload item photo for realism anchor', style: AppTextStyles.bodySmallBold),
                      SizedBox(height: 2.h),
                      Text('AI will preserve brand features & silhouette', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatioDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Output ratio', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRatio,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              items: _ratios.map((r) => DropdownMenuItem(value: r, child: Text(r, style: AppTextStyles.bodySmall))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRatio = val);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Text Language', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
              items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l, style: AppTextStyles.bodySmall))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLanguage = val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
