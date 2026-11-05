import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_icons.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/shared/widgets/interactions/bouncy_tap.dart';
import 'package:craftai_studio_mobile/shared/widgets/glass/modern_ai_button.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/tool_result_preview_sheet.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';

class AiBackgroundsView extends StatefulWidget {
  final String? initialImagePath;

  const AiBackgroundsView({super.key, this.initialImagePath});

  @override
  State<AiBackgroundsView> createState() => _AiBackgroundsViewState();
}

class _AiBackgroundsViewState extends State<AiBackgroundsView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  String? _selectedImagePath;
  String _selectedMode = 'smart'; // 'pure_white', 'smart', 'marble', 'wood', 'neon', 'custom'
  String _selectedTemplateId = 'smart';
  String _selectedRatio = 'Auto';
  String _selectedQuality = '1k'; // '1k', '2k'
  bool _harmonizeLighting = true;
  final TextEditingController _customBackdropCtrl = TextEditingController();

  final List<String> _ratios = ['Auto', '1:1', '4:5', '9:16', '16:9'];

  final List<Map<String, dynamic>> _backdropTemplates = const [
    {
      'id': 'pure_white',
      'title': 'Pure white',
      'subtitle': 'Commercial Cyclo',
      'iconData': AppIcons.backdropPureWhite,
      'mode': 'pure_white',
      'backdrop': '',
      'isFree': true,
      'accent': Color(0xFF94A3B8),
    },
    {
      'id': 'smart',
      'title': 'Smart',
      'subtitle': 'Product Keylight',
      'iconData': AppIcons.backdropSmart,
      'mode': 'smart',
      'backdrop': 'commercial photorealistic studio keylight',
      'isFree': false,
      'accent': Color(0xFF6366F1),
    },
    {
      'id': 'marble',
      'title': 'Luxury Marble',
      'subtitle': 'Studio Pedestal',
      'iconData': AppIcons.backdropMarble,
      'mode': 'marble',
      'backdrop': 'luxury marble pedestal overhead soft spotlight',
      'isFree': false,
      'accent': Color(0xFFF59E0B),
    },
    {
      'id': 'wood',
      'title': 'Warm Wood',
      'subtitle': 'Cozy Cafe Table',
      'iconData': AppIcons.backdropWood,
      'mode': 'wood',
      'backdrop': 'warm wooden tabletop cafe ambient lighting',
      'isFree': false,
      'accent': Color(0xFFD97706),
    },
    {
      'id': 'neon',
      'title': 'Cyber Neon',
      'subtitle': 'Futuristic Glow',
      'iconData': AppIcons.backdropNeon,
      'mode': 'neon',
      'backdrop': 'cyberpunk neon city illumination reflections',
      'isFree': false,
      'accent': Color(0xFF06B6D4),
    },
    {
      'id': 'custom',
      'title': 'Custom Backdrop',
      'subtitle': 'Write Any Prompt',
      'iconData': AppIcons.backdropCustom,
      'mode': 'custom',
      'backdrop': '',
      'isFree': false,
      'accent': Color(0xFF10B981),
    },
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
    _customBackdropCtrl.dispose();
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

  Future<void> _handleReplaceBackground() async {
    if (_selectedImagePath == null) {
      Get.snackbar('Image Required', 'Please upload a photo first.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    HapticFeedback.heavyImpact();
    final outUrl = await controller.runAiBackground(
      path: _selectedImagePath!,
      mode: _selectedMode,
      customBackdrop: _customBackdropCtrl.text.trim().isNotEmpty ? _customBackdropCtrl.text.trim() : null,
      aspectRatio: _selectedRatio,
      quality: _selectedQuality,
      harmonizeLighting: _harmonizeLighting,
    );

    if (outUrl != null && mounted) {
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

  @override
  Widget build(BuildContext context) {
    final isPureWhite = _selectedMode == 'pure_white';
    final creditCost = isPureWhite ? 0 : (_selectedQuality == '1k' ? 10 : 14);

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
          'AI Backgrounds',
          style: AppTextStyles.h2.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: isPureWhite
                  ? AppColors.accentSuccess.withValues(alpha: 0.15)
                  : AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
              border: Border.all(
                color: isPureWhite
                    ? AppColors.accentSuccess.withValues(alpha: 0.35)
                    : AppColors.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              isPureWhite ? 'FREE' : '$creditCost Cr',
              style: AppTextStyles.captionBold.copyWith(
                color: isPureWhite ? AppColors.accentSuccess : AppColors.primary,
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

                  // 2. Choose a Background (Segmented Control)
                  _buildModeSelector(),
                  SizedBox(height: 16.h),

                  // 3. Custom Backdrop / Prompt Refinement Input
                  if (_selectedMode != 'pure_white') ...[
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: Text(
                        _selectedTemplateId == 'custom'
                            ? 'Describe Desired Scene'
                            : 'Refine Scene Prompt (Optional)',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
                      ),
                    ),
                    TextField(
                      controller: _customBackdropCtrl,
                      style: AppTextStyles.bodySmall,
                      decoration: InputDecoration(
                        hintText: _selectedTemplateId == 'custom'
                            ? 'e.g. Modern marble podium with sunlight'
                            : 'Tweak lighting, materials or background details...',
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
                  ],

                  // 4. Output Ratio Dropdown
                  _buildRatioDropdown(),
                  SizedBox(height: 16.h),

                  // 5. Lighting Harmonization
                  if (!isPureWhite) ...[
                    _buildHarmonizationToggle(),
                    SizedBox(height: 16.h),
                  ],

                  // 6. Choose Quality
                  if (!isPureWhite) ...[
                    _buildQualitySelector(),
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
                  label: isPureWhite
                      ? 'Create Pure White ✦ Free'
                      : 'Replace background ✦ $creditCost',
                  icon: Icon(isPureWhite ? Icons.format_paint : Icons.auto_awesome, color: Colors.white, size: 18),
                  
                  isLoading: isProcessing,
                  loadingMessage: controller.processingMessage.value.isNotEmpty
                      ? controller.processingMessage.value
                      : (isPureWhite ? 'Creating pure white cutout...' : 'Synthesizing backdrop...'),
                  onPressed: isProcessing ? null : _handleReplaceBackground,
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
                      Text('Upload photo to replace backdrop', style: AppTextStyles.bodySmallBold),
                      SizedBox(height: 2.h),
                      Text('Supports JPG, PNG, WEBP', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose a background', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
        SizedBox(height: 8.h),
        SizedBox(
          height: (112.h).clamp(108.0, 130.0),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _backdropTemplates.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, idx) {
              final tmpl = _backdropTemplates[idx];
              final isSel = _selectedTemplateId == tmpl['id'];
              final accent = tmpl['accent'] as Color;

              return BouncyTap(
                onTap: () {
                  setState(() {
                    _selectedTemplateId = tmpl['id'] as String;
                    _selectedMode = tmpl['mode'] as String;
                    if (tmpl['id'] != 'custom' && tmpl['backdrop'].isNotEmpty) {
                      _customBackdropCtrl.text = tmpl['backdrop'] as String;
                    } else if (tmpl['id'] == 'pure_white') {
                      _customBackdropCtrl.clear();
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 108.w,
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: isSel ? accent.withValues(alpha: 0.15) : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    border: Border.all(
                      color: isSel ? accent : AppColors.border,
                      width: isSel ? 1.5.w : 1.0.w,
                    ),
                  ),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(tmpl['iconData'] as IconData, size: 18.sp, color: accent),
                            if (tmpl['isFree'] == true)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                                decoration: BoxDecoration(
                                  color: AppColors.accentSuccess.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4.r),
                                ),
                                child: Text('FREE', style: AppTextStyles.captionXs.copyWith(color: AppColors.accentSuccess, fontSize: 8.sp, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          tmpl['title'] as String,
                          style: AppTextStyles.captionBold.copyWith(
                            fontSize: 11.sp,
                            color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          tmpl['subtitle'] as String,
                          style: AppTextStyles.captionXs.copyWith(fontSize: 9.sp, color: AppColors.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildHarmonizationToggle() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined, size: 14.sp, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Text('Lighting Harmonization', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  'Synthesize rim lighting & color bounce between subject and backdrop',
                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: _harmonizeLighting,
            activeThumbColor: AppColors.primary,
            onChanged: (val) => setState(() => _harmonizeLighting = val),
          ),
        ],
      ),
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
            Expanded(
              child: _buildQualityOption('1k', '1K Standard', '10 Cr'),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildQualityOption('2k', '2K Ultra HD', '14 Cr'),
            ),
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
