import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'tool_result_preview_sheet.dart';

class AiExpandSheet extends StatefulWidget {
  const AiExpandSheet({super.key});

  static void show(BuildContext context) {
    if (Get.isRegistered<ToolsController>()) {
      Get.find<ToolsController>().clearActiveSession();
    }
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
  String _selectedAlignment = 'auto'; // 'auto', 'center', 'left', 'right', 'top', 'bottom'
  String _selectedEngine = 'diffusion'; // 'diffusion', 'fast'
  final TextEditingController _promptController = TextEditingController();

  final List<String> _ratios = [
    '1:1', '3:4', '4:3', '9:16', '16:9', '2:3', '3:2', '2:1', '1:2'
  ];

  @override
  void initState() {
    super.initState();
    controller.clearActiveSession();
  }

  @override
  void dispose() {
    _promptController.dispose();
    controller.clearActiveSession();
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
    final creditCost = _selectedQuality == '1k' ? 10 : 14;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.90,
          decoration: BoxDecoration(
            color: AppColors.glassDarkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            border: Border(
              top: BorderSide(color: AppColors.glassBorder, width: 1.2.w),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              SizedBox(height: 10.h),
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              // Header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 8.h, 16.w, 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AI Expand',
                      style: AppTextStyles.h2.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    BouncyTap(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight.withValues(alpha: 0.60),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 18.sp, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.h, color: AppColors.glassBorderSubtle),

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

                    // 3. Subject Placement Alignment
                    _buildAlignmentSelector(),
                    SizedBox(height: 16.h),

                    // 4. Canvas Placement View
                    _buildCanvasPreview(),
                    SizedBox(height: 16.h),

                    // 5. Scene Prompt Section (Optional)
                    _buildScenePromptSection(),
                    SizedBox(height: 16.h),

                    // 6. Engine Selector
                    _buildEngineSelector(),
                    SizedBox(height: 16.h),

                    // 7. Choose Quality
                    _buildQualitySelector(),
                    SizedBox(height: 16.h),
                  ],
                ),
              ),

              // Bottom Action Button
              Container(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                decoration: BoxDecoration(
                  color: AppColors.glassDarkSurface,
                  border: Border(top: BorderSide(color: AppColors.glassBorderSubtle)),
                ),
                child: Obx(() {
                  final isProcessing = controller.isProcessing.value;
                  return ModernAiButton(
                    label: 'Expand image ✦ $creditCost',
                    isLoading: isProcessing,
                    loadingMessage: controller.processingMessage.value.isNotEmpty
                        ? controller.processingMessage.value
                        : 'Expanding canvas...',
                    onPressed: isProcessing ? null : _handleExpand,
                  );
                }),
              ),
            ],
          ),
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

  Alignment _getCanvasAlignment() {
    switch (_selectedAlignment) {
      case 'left':
        return Alignment.centerLeft;
      case 'right':
        return Alignment.centerRight;
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'center':
      case 'auto':
      default:
        return Alignment.center;
    }
  }

  Widget _buildAlignmentSelector() {
    final alignments = [
      {'id': 'auto', 'label': 'Auto ✦', 'icon': Icons.auto_awesome},
      {'id': 'center', 'label': 'Center', 'icon': Icons.filter_center_focus},
      {'id': 'left', 'label': 'Left', 'icon': Icons.align_horizontal_left},
      {'id': 'right', 'label': 'Right', 'icon': Icons.align_horizontal_right},
      {'id': 'top', 'label': 'Top', 'icon': Icons.align_vertical_top},
      {'id': 'bottom', 'label': 'Bottom', 'icon': Icons.align_vertical_bottom},
    ];

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
              Text('Subject Placement', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
              Text('Smart alignment', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
            ],
          ),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: alignments.map((a) {
                final isSel = _selectedAlignment == a['id'];
                return Padding(
                  padding: EdgeInsets.only(right: 8.w),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedAlignment = a['id'] as String),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.surface : AppColors.background,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.border,
                          width: isSel ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            a['icon'] as IconData,
                            size: 13.sp,
                            color: isSel ? AppColors.primary : AppColors.textSecondary,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            a['label'] as String,
                            style: AppTextStyles.captionBold.copyWith(
                              color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
                              fontSize: 11.5.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenePromptSection() {
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
                  Icon(Icons.auto_fix_high, size: 15.sp, color: AppColors.primary),
                  SizedBox(width: 6.w),
                  Text('Scene Prompt', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
                ],
              ),
              Text('Optional', style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary)),
            ],
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _promptController,
            maxLines: 2,
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.textPrimary, fontSize: 13.sp),
            decoration: InputDecoration(
              hintText: 'Describe scenery extension (leave blank for auto vision match)',
              hintStyle: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                borderSide: BorderSide(color: AppColors.primary, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngineSelector() {
    final engines = [
      {'id': 'diffusion', 'title': 'HD Generative (FLUX)', 'desc': 'Photorealistic scene & depth'},
      {'id': 'fast', 'title': 'Fast Neural', 'desc': 'Reflection texture outpaint'},
    ];

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
          Text('Outpaint Engine', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
          SizedBox(height: 10.h),
          Row(
            children: engines.map((e) {
              final isSel = _selectedEngine == e['id'];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: e['id'] == 'diffusion' ? 8.w : 0),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedEngine = e['id'] as String),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isSel ? AppColors.surface : AppColors.background,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        border: Border.all(
                          color: isSel ? AppColors.primary : AppColors.border,
                          width: isSel ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e['title'] as String,
                            style: AppTextStyles.captionBold.copyWith(
                              color: isSel ? AppColors.textPrimary : AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            e['desc'] as String,
                            style: AppTextStyles.captionXs.copyWith(color: AppColors.textTertiary, fontSize: 10.sp),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _getTargetRatioValue() {
    switch (_selectedRatio) {
      case '16:9':
        return 16 / 9;
      case '9:16':
        return 9 / 16;
      case '4:5':
        return 4 / 5;
      case '1:1':
        return 1.0;
      case '4:3':
        return 4 / 3;
      case '3:4':
        return 3 / 4;
      case '2:3':
        return 2 / 3;
      case '3:2':
        return 3 / 2;
      default:
        return 16 / 9;
    }
  }

  Widget _buildCanvasPreview() {
    final targetAspect = _getTargetRatioValue();

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
                  Text('Canvas Preview', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                    ),
                    child: Text(
                      'Target: $_selectedRatio • ${_selectedAlignment.toUpperCase()}',
                      style: AppTextStyles.captionXs.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (_selectedImagePath != null)
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
            height: 180.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              border: Border.all(color: AppColors.border, style: BorderStyle.solid),
            ),
            child: _selectedImagePath != null
                ? Center(
                    child: Container(
                      margin: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5), width: 1.2),
                      ),
                      child: AspectRatio(
                        aspectRatio: targetAspect,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Canvas expansion zone guide
                            Container(
                              color: AppColors.surfaceLight.withValues(alpha: 0.4),
                              child: Center(
                                child: Icon(
                                  Icons.all_out_rounded,
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  size: 32.sp,
                                ),
                              ),
                            ),
                            // Nested source image with dynamic alignment positioning
                            Align(
                              alignment: _getCanvasAlignment(),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                                child: _selectedImagePath!.startsWith('http')
                                    ? CachedNetworkImage(imageUrl: _selectedImagePath!, fit: BoxFit.contain)
                                    : Image.file(File(_selectedImagePath!), fit: BoxFit.contain),
                              ),
                            ),
                          ],
                        ),
                      ),
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
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
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
      Navigator.of(context).pop();
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
}
