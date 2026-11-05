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

class AiExpandView extends StatefulWidget {
  final String? initialImagePath;

  const AiExpandView({super.key, this.initialImagePath});

  @override
  State<AiExpandView> createState() => _AiExpandViewState();
}

class _AiExpandViewState extends State<AiExpandView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  String? _selectedImagePath;
  String _selectedRatio = '16:9';
  String _selectedQuality = '1k'; // '1k', '2k'
  String _selectedAlignment = 'auto'; // 'auto', 'center', 'left', 'right', 'top', 'bottom'
  String _selectedEngine = 'diffusion'; // 'diffusion', 'fast'
  final TextEditingController _promptController = TextEditingController();

  final List<String> _ratios = [
    '1:1', '3:4', '4:3', '9:16', '16:9', '2:3', '3:2', '2:1', '1:2'
  ];

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
    _promptController.dispose();
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

  Future<void> _handleExpand() async {
    if (_selectedImagePath == null) {
      Get.snackbar('Image Required', 'Please upload a photo to expand.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    HapticFeedback.heavyImpact();
    final promptText = _promptController.text.trim();
    final outUrl = await controller.runAiExpand(
      path: _selectedImagePath!,
      targetRatio: _selectedRatio,
      quality: _selectedQuality,
      alignment: _selectedAlignment,
      prompt: promptText.isNotEmpty ? promptText : null,
      engine: _selectedEngine,
    );

    if (outUrl != null && mounted) {
      final engineLabel = _selectedEngine == 'diffusion' ? 'HD Generative' : 'Fast';
      ToolResultPreviewSheet.show(
        context: context,
        title: 'AI Expand',
        resultImageUrl: outUrl,
        originalImageUrl: _selectedImagePath,
        creditsUsed: _selectedQuality == '1k' ? 10.0 : 14.0,
        badgeText: '$_selectedRatio • ${_selectedAlignment.toUpperCase()} • $engineLabel • $_selectedQuality',
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
          'AI Expand',
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
                  // 1. Upload Section
                  _buildUploadSection(),
                  SizedBox(height: 16.h),

                  // 2. Target Ratio
                  _buildRatioSelector(),
                  SizedBox(height: 16.h),

                  // 3. Subject Placement
                  _buildAlignmentSelector(),
                  SizedBox(height: 16.h),

                  // 4. Outpainting Engine
                  _buildEngineSelector(),
                  SizedBox(height: 16.h),

                  // 5. Prompt Guidance (Optional)
                  _buildPromptInput(),
                  SizedBox(height: 16.h),

                  // 6. Quality Preset
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
                  label: 'Expand image ✦ $creditCost',
                  icon: Icon(Icons.aspect_ratio, color: Colors.white, size: 18),
                  
                  isLoading: isProcessing,
                  loadingMessage: controller.processingMessage.value.isNotEmpty
                      ? controller.processingMessage.value
                      : 'Outpainting canvas...',
                  onPressed: isProcessing ? null : _handleExpand,
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
                      Text('Upload photo to outpaint / extend', style: AppTextStyles.bodySmallBold),
                      SizedBox(height: 2.h),
                      Text('Select any vertical, square, or wide photo', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Target ratio', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        SizedBox(
          height: 38.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _ratios.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, idx) {
              final r = _ratios[idx];
              final isSel = _selectedRatio == r;
              return BouncyTap(
                onTap: () => setState(() => _selectedRatio = r),
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
                      r,
                      style: AppTextStyles.captionBold.copyWith(
                        color: isSel ? AppColors.primary : AppColors.textSecondary,
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

  Widget _buildAlignmentSelector() {
    final alignments = [
      {'key': 'auto', 'label': 'Auto ✦'},
      {'key': 'center', 'label': 'Center'},
      {'key': 'left', 'label': 'Left Align'},
      {'key': 'right', 'label': 'Right Align'},
      {'key': 'top', 'label': 'Top Align'},
      {'key': 'bottom', 'label': 'Bottom Align'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Subject Placement', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: alignments.map((a) {
            final isSel = _selectedAlignment == a['key'];
            return BouncyTap(
              onTap: () => setState(() => _selectedAlignment = a['key']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.border,
                    width: isSel ? 1.5.w : 1.0.w,
                  ),
                ),
                child: Text(
                  a['label']!,
                  style: AppTextStyles.captionBold.copyWith(
                    color: isSel ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildEngineSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Outpainting Engine', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        Row(
          children: [
            Expanded(
              child: _buildEngineOption('diffusion', 'HD Generative (Flux)', 'Rich detail, high coherence'),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildEngineOption('fast', 'Fast Outpaint', 'Instant fill, lower detail'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEngineOption(String engineKey, String title, String subtitle) {
    final isSel = _selectedEngine == engineKey;
    return BouncyTap(
      onTap: () => setState(() => _selectedEngine = engineKey),
      child: Container(
        padding: EdgeInsets.all(10.r),
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
            Text(
              title,
              style: AppTextStyles.captionBold.copyWith(
                color: isSel ? AppColors.primary : AppColors.textPrimary,
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary, fontSize: 9.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prompt Guidance (Optional)', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 6.h),
        TextField(
          controller: _promptController,
          style: AppTextStyles.bodySmall,
          decoration: InputDecoration(
            hintText: 'e.g. Luxurious modern living room with large glass windows',
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
