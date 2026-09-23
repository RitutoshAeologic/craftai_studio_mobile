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

class MarketingPosterSheet extends StatefulWidget {
  const MarketingPosterSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MarketingPosterSheet(),
    );
  }

  @override
  State<MarketingPosterSheet> createState() => _MarketingPosterSheetState();
}

class _MarketingPosterSheetState extends State<MarketingPosterSheet> {
  final ToolsController controller = Get.find<ToolsController>();
  final TextEditingController _topicCtrl = TextEditingController();
  final TextEditingController _headlineCtrl = TextEditingController();

  String? _selectedImagePath;
  String _selectedCategory = 'Beverage';
  String _selectedRatio = '4:5';
  String _selectedLanguage = 'Auto (match my input)';
  String _selectedQuality = '1k';

  final List<String> _categories = ['Beverage', 'Fashion', 'Hiring', 'Flash Sale', 'Event', 'Commercial'];
  final List<String> _ratios = ['4:5', '9:16', '1:1', '16:9', 'Auto'];
  final List<String> _languages = ['Auto (match my input)', 'English', 'Spanish', 'French', 'Hindi'];

  @override
  void dispose() {
    _topicCtrl.dispose();
    _headlineCtrl.dispose();
    super.dispose();
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
                  'Marketing Poster',
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

          // Scrollable Form
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              children: [
                // Set up the basics subtitle
                Text('Set up the basics', style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
                SizedBox(height: 2.h),
                Text('Brand & topic, copy, size and language', style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary)),
                SizedBox(height: 14.h),

                // 1. Poster Topic Field
                _buildTopicField(),
                SizedBox(height: 14.h),

                // 2. Featured Product Photo (Optional)
                _buildUploadSection(),
                SizedBox(height: 14.h),

                // 3. Category Chips
                _buildCategoryChips(),
                SizedBox(height: 14.h),

                // 3. Custom Headline (Optional)
                _buildHeadlineField(),
                SizedBox(height: 14.h),

                // 4. Aspect Ratio Dropdown
                _buildRatioDropdown(),
                SizedBox(height: 14.h),

                // 5. Language Dropdown
                _buildLanguageDropdown(),
                SizedBox(height: 14.h),

                // 6. Quality Selection
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
                  onPressed: isProcessing ? null : _handleGeneratePoster,
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
                                  : 'Designing poster...',
                              style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 13.sp),
                            ),
                          ],
                        )
                      : Text(
                          'Generate Poster ✦ $creditCost',
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

  Widget _buildTopicField() {
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
          RichText(
            text: TextSpan(
              text: 'Poster topic ',
              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
              children: [
                TextSpan(text: '*', style: TextStyle(color: Colors.red, fontSize: 13.sp)),
              ],
            ),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _topicCtrl,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'e.g. Summer iced coffee launch',
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

  Widget _buildCategoryChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
        SizedBox(height: 8.h),
        SizedBox(
          height: 36.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (_, idx) {
              final cat = _categories[idx];
              final isSel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                    border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: AppTextStyles.captionBold.copyWith(
                        color: isSel ? Colors.white : AppColors.textSecondary,
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeadlineField() {
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
              Text('Headline Copy', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
              Text('Optional', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
            ],
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _headlineCtrl,
            style: AppTextStyles.bodySmall,
            decoration: InputDecoration(
              hintText: 'e.g. Sip Into Pure Summer',
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
          Text('Aspect ratio', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
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
          Text('Poster text language', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
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
                    Icon(Icons.add_photo_alternate_outlined, size: 18.sp, color: AppColors.textPrimary),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Featured Product / Photo',
                        style: AppTextStyles.bodySmallBold.copyWith(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Optional',
                    style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary),
                  ),
                  SizedBox(width: 4.w),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      _selectedImagePath != null ? Icons.change_circle_outlined : Icons.add_circle,
                      color: AppColors.primary,
                      size: 22.sp,
                    ),
                    onPressed: () => _showPickerSheet(),
                  ),
                ],
              ),
            ],
          ),
          if (_selectedImagePath != null) ...[
            SizedBox(height: 10.h),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  child: SizedBox(
                    height: 100.h,
                    width: double.infinity,
                    child: _selectedImagePath!.startsWith('http')
                        ? CachedNetworkImage(imageUrl: _selectedImagePath!, fit: BoxFit.contain)
                        : Image.file(File(_selectedImagePath!), fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 4.h,
                  right: 4.w,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedImagePath = null),
                    child: Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showPickerSheet() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Product / Subject Photo', style: AppTextStyles.h3),
              SizedBox(height: 16.h),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: Text('Choose from Gallery', style: AppTextStyles.bodyMedium),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await controller.pickImage(ImageSource.gallery);
                  if (file != null) {
                    setState(() => _selectedImagePath = file.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: Text('Take a Photo', style: AppTextStyles.bodyMedium),
                onTap: () async {
                  Navigator.pop(ctx);
                  final file = await controller.pickImage(ImageSource.camera);
                  if (file != null) {
                    setState(() => _selectedImagePath = file.path);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGeneratePoster() async {
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      Get.snackbar('Topic Required', 'Please enter a poster topic.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    final outUrl = await controller.runMarketingPoster(
      topic: topic,
      path: _selectedImagePath,
      category: _selectedCategory,
      aspectRatio: _selectedRatio,
      headline: _headlineCtrl.text.trim().isNotEmpty ? _headlineCtrl.text.trim() : null,
      language: _selectedLanguage,
      quality: _selectedQuality,
    );

    if (outUrl != null && mounted) {
      Navigator.of(context).pop();
      ToolResultPreviewSheet.show(
        context: context,
        title: 'Marketing Poster',
        resultImageUrl: outUrl,
        originalImageUrl: _selectedImagePath,
        creditsUsed: _selectedQuality == '1k' ? 10.0 : 14.0,
        badgeText: '$_selectedCategory • $_selectedRatio • $_selectedQuality',
        enableBeforeAfter: _selectedImagePath != null,
      );
    }
  }
}
