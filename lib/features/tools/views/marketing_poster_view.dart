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

class MarketingPosterView extends StatefulWidget {
  final String? initialImagePath;

  const MarketingPosterView({super.key, this.initialImagePath});

  @override
  State<MarketingPosterView> createState() => _MarketingPosterViewState();
}

class _MarketingPosterViewState extends State<MarketingPosterView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  final TextEditingController _topicCtrl = TextEditingController();
  final TextEditingController _headlineCtrl = TextEditingController();
  final TextEditingController _subtextCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController();

  String? _selectedImagePath;
  String _selectedCategory = 'Beverage';
  String _selectedRatio = '4:5';
  String _selectedLanguage = 'Auto (match my input)';
  String _selectedQuality = '1k';

  final List<String> _categories = ['Beverage', 'Fashion', 'Hiring', 'Flash Sale', 'Event', 'Commercial'];
  final List<String> _ratios = ['4:5', '9:16', '1:1', '16:9', 'Auto'];
  final List<String> _languages = ['Auto (match my input)', 'English', 'Spanish', 'French', 'Hindi'];

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
    _topicCtrl.dispose();
    _headlineCtrl.dispose();
    _subtextCtrl.dispose();
    _discountCtrl.dispose();
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
    final topic = _topicCtrl.text.trim();
    if (topic.isEmpty) {
      Get.snackbar('Topic Required', 'Please enter a poster theme, prompt, or promo subject.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    HapticFeedback.heavyImpact();
    final outUrl = await controller.runMarketingPoster(
      topic: topic,
      category: _selectedCategory,
      headline: _headlineCtrl.text.trim().isNotEmpty ? _headlineCtrl.text.trim() : null,
      subtext: _subtextCtrl.text.trim().isNotEmpty ? _subtextCtrl.text.trim() : null,
      discountBadge: _discountCtrl.text.trim().isNotEmpty ? _discountCtrl.text.trim() : null,
      path: _selectedImagePath,
      aspectRatio: _selectedRatio,
      language: _selectedLanguage,
      quality: _selectedQuality,
    );

    if (outUrl != null && mounted) {
      ToolResultPreviewSheet.show(
        context: context,
        title: 'Marketing Poster',
        resultImageUrl: outUrl,
        originalImageUrl: _selectedImagePath,
        creditsUsed: _selectedQuality == '1k' ? 10.0 : 14.0,
        badgeText: '$_selectedCategory • $_selectedRatio',
        enableBeforeAfter: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditCost = _selectedQuality == '1k' ? 10 : 14;

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
          'Marketing Poster',
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
              '$creditCost Cr',
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
                  // 1. Topic Input
                  Text('Set up the basics', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 8.h),
                  Text('Poster Topic / Description *', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _topicCtrl,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'e.g. Artisanal Cold Brew Coffee Launch',
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

                  // 2. Poster Category Chips
                  Text('Poster Category', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 8.h),
                  SizedBox(
                    height: 38.h,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      separatorBuilder: (_, __) => SizedBox(width: 8.w),
                      itemBuilder: (context, idx) {
                        final cat = _categories[idx];
                        final isSel = _selectedCategory == cat;
                        return BouncyTap(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                              border: Border.all(
                                color: isSel ? AppColors.primary : AppColors.border,
                                width: isSel ? 1.5.w : 1.0.w,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                cat,
                                style: AppTextStyles.captionBold.copyWith(
                                  color: isSel ? AppColors.primary : AppColors.textSecondary,
                                  fontSize: 11.sp,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // 3. Headline Copy
                  Text('Headline Copy', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _headlineCtrl,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'e.g. Pure Energy in Every Drop',
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

                  // 4. Subtitle / Description
                  Text('Subtitle / Description', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _subtextCtrl,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'e.g. Brewed for 24 hours with organic beans',
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

                  // 5. Discount / Promo Badge
                  Text('Discount / Promo Badge', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  SizedBox(height: 6.h),
                  TextField(
                    controller: _discountCtrl,
                    style: AppTextStyles.bodySmall,
                    decoration: InputDecoration(
                      hintText: 'e.g. 20% OFF THIS WEEKEND',
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

                  // 6. Anchor Image
                  _buildUploadSection(),
                  SizedBox(height: 16.h),

                  // 7. Output Ratio
                  _buildRatioDropdown(),
                  SizedBox(height: 16.h),

                                    // 8. Language
                  _buildLanguageSelector(),
                  SizedBox(height: 16.h),
                  // 9. Quality preset
                  _buildQualitySelector(),
                  SizedBox(height: 16.h),
                ],
              ),
            ),

            // Bottom Generate Button
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Obx(() {
                final isProcessing = controller.isProcessing.value;
                return ModernAiButton(
                  label: 'Generate Poster ✦ $creditCost',
                  icon: Icon(Icons.campaign_rounded, color: Colors.white, size: 18),
                  
                  isLoading: isProcessing,
                  loadingMessage: controller.processingMessage.value.isNotEmpty
                      ? controller.processingMessage.value
                      : 'Designing commercial poster...',
                  onPressed: isProcessing ? null : _handleGenerate,
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
            Text('Anchor Product Image (Optional)', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
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
                      Text('Upload bottle, model, or item photo', style: AppTextStyles.bodySmallBold),
                      SizedBox(height: 2.h),
                      Text('AI will place it realistically in the poster', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
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


  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Poster text language', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedLanguage,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              borderSide: BorderSide(color: AppColors.border),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            filled: true,
            fillColor: AppColors.surface,
          ),
          items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l, style: AppTextStyles.bodySmall))).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedLanguage = val);
          },
        ),
      ],
    );
  }

  Widget _buildQualitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quality preset', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        Row(
          children: [
            Expanded(child: _buildQualityOption('1k', '1K Standard', '10 Cr')),
            SizedBox(width: 8.w),
            Expanded(child: _buildQualityOption('2k', '2K Ultra HD', '14 Cr')),
          ],
        ),
      ],
    );
  }

  Widget _buildQualityOption(String qualityKey, String title, String costLabel) {
    final isSelected = _selectedQuality == qualityKey;
    return GestureDetector(
      onTap: () => setState(() => _selectedQuality = qualityKey),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : AppColors.surfaceLight,
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
}
