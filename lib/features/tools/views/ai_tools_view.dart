import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/shared/widgets/app_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import '../controllers/tools_controller.dart';
import '../../remix/views/remix_chat_view.dart';
import '../widgets/ai_backgrounds_sheet.dart';
import '../widgets/ai_expand_sheet.dart';
import '../widgets/marketing_poster_sheet.dart';
import '../widgets/product_detail_sheet.dart';
import '../widgets/upscale_sheet.dart';

class AiToolsView extends StatelessWidget {
  const AiToolsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ToolsController controller = Get.isRegistered<ToolsController>()
        ? Get.find<ToolsController>()
        : Get.put(ToolsController());
    final ShellController shellCtrl = Get.isRegistered<ShellController>()
        ? Get.find<ShellController>()
        : Get.put(ShellController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // =================================================================
            // HEADER BAR
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Creative Toolbox',
                            style: AppTextStyles.h1.copyWith(fontSize: 20.sp),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Zero-token neural processing & tools',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt, color: AppColors.primary, size: 14.sp),
                          SizedBox(width: 4.w),
                          Obx(() => Text(
                            '${shellCtrl.userCredits.value.toStringAsFixed(0)} Cr',
                            style: AppTextStyles.captionBold.copyWith(color: AppColors.primary),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // =================================================================
            // CATEGORY FILTER CHIPS
            // =================================================================
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                  itemCount: controller.categories.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, idx) {
                    final cat = controller.categories[idx];
                    return Obx(() {
                      final isSel = controller.selectedCategory.value == cat;
                      return GestureDetector(
                        onTap: () => controller.setCategory(cat),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                            border: Border.all(
                              color: isSel ? AppColors.primary : AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              cat == 'all' ? 'All Skills' : cat,
                              style: AppTextStyles.captionBold.copyWith(
                                color: isSel ? Colors.white : AppColors.textSecondary,
                                fontSize: 11.sp,
                              ),
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ),

            // =================================================================
            // INTERACTIVE TOOL WORKSPACE (Background Remover Hero Card)
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: _buildInteractiveHeroCard(context, controller),
              ),
            ),

            // =================================================================
            // ALL CREATIVE TOOLS CATALOG
            // =================================================================
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Get designs done fast with Skills',
                      style: AppTextStyles.h2.copyWith(fontSize: 18.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'Smart workflows crafted for every use case',
                      style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

            Obx(() => SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final tool = controller.filteredTools[index];
                    return _buildToolListCard(context, tool, controller);
                  },
                  childCount: controller.filteredTools.length,
                ),
              ),
            )),

            SliverToBoxAdapter(
              child: SizedBox(height: 24.h),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveHeroCard(BuildContext context, ToolsController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(AppDimens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00F5D4), Color(0xFF0EA5E9)],
                        ),
                        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                      ),
                      child: Text('✂️', style: TextStyle(fontSize: 16.sp)),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Background Remover',
                            style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Zero-Token • Local CPU U2-Net',
                            style: AppTextStyles.captionXs.copyWith(color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.accentSuccess.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
                child: Text(
                  'FREE',
                  style: AppTextStyles.captionBold.copyWith(
                    color: AppColors.accentSuccess,
                    fontSize: 10.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDimens.vSpacingMd),

          // Upload or Result View Area
          Obx(() {
            if (controller.resultImageUrl.value != null) {
              final resultUrl = controller.resultImageUrl.value!;
              return _buildResultPreview(context, controller, resultUrl);
            }

            if (controller.inputImagePath.value != null) {
              final inPath = controller.inputImagePath.value!;
              return _buildInputPendingAction(context, controller, inPath);
            }

            return _buildUploadPromptCard(context, controller);
          }),
        ],
      ),
    );
  }

  Widget _buildUploadPromptCard(BuildContext context, ToolsController controller) {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(context, controller),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 12.w),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusMd),
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary, size: 28.sp),
            SizedBox(height: 8.h),
            Text(
              'Select Photo to Cut Out',
              style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 13.sp),
            ),
            SizedBox(height: 2.h),
            Text(
              'Outputs transparent PNG cutout in ~2 seconds',
              style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputPendingAction(BuildContext context, ToolsController controller, String path) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusMd),
              child: SizedBox(
                height: 140.h,
                width: double.infinity,
                child: path.startsWith('data:')
                    ? Image.memory(base64Decode(path.split(',').last), fit: BoxFit.cover)
                    : path.startsWith('http')
                        ? CachedNetworkImage(imageUrl: path, fit: BoxFit.cover)
                        : Image.file(File(path), fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 6.h,
              right: 6.w,
              child: GestureDetector(
                onTap: controller.clearActiveSession,
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: AppColors.accentError, size: 14.sp),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppDimens.vSpacingSm),
        Obx(() {
          if (controller.isProcessing.value) {
            return Container(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14.w,
                    height: 14.w,
                    child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    controller.processingMessage.value,
                    style: AppTextStyles.captionXs.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            );
          }
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => controller.runBackgroundRemoval(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
              ),
              icon: Icon(Icons.auto_fix_high, size: 16.sp, color: Colors.white),
              label: Text(
                'Remove Background Now (Free)',
                style: AppTextStyles.captionBold.copyWith(color: Colors.white),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildResultPreview(BuildContext context, ToolsController controller, String resultUrl) {
    return Column(
      children: [
        Container(
          height: 150.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.accentSuccess.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Stack(
              children: [
                Center(
                  child: AppNetworkImage(
                    imageUrl: resultUrl,
                    fit: BoxFit.contain,
                    placeholder: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                ),
                Positioned(
                  top: 8.h,
                  left: 8.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: AppColors.accentSuccess,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      'Cutout Ready',
                      style: AppTextStyles.captionXs.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: AppDimens.vSpacingSm),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: controller.clearActiveSession,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                ),
                icon: Icon(Icons.refresh, size: 14.sp, color: AppColors.textSecondary),
                label: Text('New Photo', style: AppTextStyles.captionXs.copyWith(color: AppColors.textPrimary)),
              ),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Inject transparent cutout into Studio as reference
                  final studioCtrl = Get.find<StudioController>();
                  studioCtrl.referenceImages.clear();
                  studioCtrl.addReferenceImage(resultUrl);
                  Get.find<ShellController>().switchTab(1);
                  Get.snackbar(
                    'Cutout Injected! 🎨',
                    'Transparent cutout loaded as Studio reference photo.',
                    snackPosition: SnackPosition.BOTTOM,
                    backgroundColor: AppColors.surface,
                    colorText: AppColors.primary,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
                ),
                icon: Icon(Icons.palette_outlined, size: 14.sp, color: Colors.white),
                label: Text('Use in Studio', style: AppTextStyles.captionBold.copyWith(color: Colors.white)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToolListCard(BuildContext context, Map<String, dynamic> tool, ToolsController controller) {
    final toolId = tool['id'] as String;
    final bgTint = (tool['bgTint'] as Color?) ?? AppColors.surface;
    final accentColor = (tool['accentColor'] as Color?) ?? AppColors.primary;

    return InkWell(
      onTap: () {
        switch (toolId) {
          case 'bg_remover':
            _showImageSourceSheet(context, controller);
            break;
          case 'ai_background':
            AiBackgroundsSheet.show(context);
            break;
          case 'ai_expand':
            AiExpandSheet.show(context);
            break;
          case 'upscaler':
            UpscaleSheet.show(context);
            break;
          case 'product_detail':
            ProductDetailSheet.show(context);
            break;
          case 'marketing_poster':
            MarketingPosterSheet.show(context);
            break;
          case 'remix_lab':
            _showRemixImageSourceSheet(context);
            break;
          default:
            _showImageSourceSheet(context, controller);
        }
      },
      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bgTint,
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: accentColor.withValues(alpha: 0.20), width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular icon badge with white circle
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(tool['icon'] as String, style: TextStyle(fontSize: 20.sp)),
              ),
            ),
            SizedBox(width: 14.w),

            // Title, Subtitle, and Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tool['title'] as String,
                          style: AppTextStyles.bodyMediumBold.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                        ),
                        child: Text(
                          tool['credits'] as String,
                          style: AppTextStyles.captionXs.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    tool['desc'] as String,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.captionXs.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Icon(Icons.arrow_forward_ios, size: 12.sp, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  void _showRemixImageSourceSheet(BuildContext context) {
    final picker = ImagePicker();
    final libraryCtrl = Get.isRegistered<LibraryController>()
        ? Get.find<LibraryController>()
        : Get.put(LibraryController());
    final shellCtrl = Get.isRegistered<ShellController>()
        ? Get.find<ShellController>()
        : Get.put(ShellController());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 12.h),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                ),
              ),
              Text('Choose Artwork to Remix', style: AppTextStyles.h3),
              SizedBox(height: 4.h),
              Text(
                'Select from your library or upload an anchor image',
                style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
              ),
              SizedBox(height: 16.h),

              // Recent Library Generations (Web parity: "Remix from Your Recent Generations")
              Obx(() {
                final creations = libraryCtrl.myCreations;
                if (creations.isEmpty) return const SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Your Recent Creations', style: AppTextStyles.captionBold),
                        Text(
                          '${creations.length} saved',
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    SizedBox(
                      height: 90.h,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: creations.length.clamp(0, 10),
                        separatorBuilder: (_, __) => SizedBox(width: 8.w),
                        itemBuilder: (context, idx) {
                          final job = creations[idx];
                          return GestureDetector(
                            onTap: () {
                              Get.back();
                              Get.to(
                                () => const RemixChatView(),
                                arguments: {
                                  'anchorImageUrl': job.previewUrl,
                                  'sourceType': 'library',
                                  'authorName': 'Your Creation',
                                  'initialPrompt': job.prompt,
                                },
                                transition: Transition.rightToLeft,
                              );
                            },
                            child: Container(
                              width: 80.w,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                border: Border.all(color: AppColors.border),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  AppNetworkImage(
                                    imageUrl: job.previewUrl,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 4.w),
                                      color: Colors.black.withValues(alpha: 0.6),
                                      child: Text(
                                        job.prompt,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 16.h),
                    const Divider(color: AppColors.border, height: 1),
                    SizedBox(height: 8.h),
                  ],
                );
              }),

              // Source Options
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.photo_library_outlined, color: AppColors.primary, size: 20.sp),
                ),
                title: Text('From Device Gallery', style: AppTextStyles.bodyMediumBold),
                subtitle: Text('Upload any local image from photo library', style: AppTextStyles.captionXs),
                onTap: () async {
                  Get.back();
                  final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
                  if (picked != null) {
                    Get.to(
                      () => const RemixChatView(),
                      arguments: {
                        'anchorImageUrl': picked.path,
                        'sourceType': 'custom',
                        'authorName': 'My Upload',
                        'initialPrompt': 'Remix this photo with cinematic styling',
                      },
                      transition: Transition.rightToLeft,
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: AppColors.primary, size: 20.sp),
                ),
                title: Text('Take Camera Selfie', style: AppTextStyles.bodyMediumBold),
                subtitle: Text('Capture a live portrait or reference photo', style: AppTextStyles.captionXs),
                onTap: () async {
                  Get.back();
                  final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
                  if (picked != null) {
                    Get.to(
                      () => const RemixChatView(),
                      arguments: {
                        'anchorImageUrl': picked.path,
                        'sourceType': 'custom',
                        'authorName': 'My Selfie',
                        'initialPrompt': 'Remix this portrait with artistic styling',
                      },
                      transition: Transition.rightToLeft,
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(Icons.explore_outlined, color: AppColors.primary, size: 20.sp),
                ),
                title: Text('Browse Community Explore', style: AppTextStyles.bodyMediumBold),
                subtitle: Text('Remix trending community styles & prompts', style: AppTextStyles.captionXs),
                onTap: () {
                  Get.back();
                  shellCtrl.switchTab(0); // Switch to Explore Tab
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageSourceSheet(BuildContext context, ToolsController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusLg)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppDimens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Choose Photo Source', style: AppTextStyles.h3),
              SizedBox(height: AppDimens.vSpacingMd),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppColors.primary, size: 22.sp),
                title: Text('Gallery', style: AppTextStyles.bodyMediumBold),
                onTap: () {
                  Get.back();
                  controller.pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppColors.primary, size: 22.sp),
                title: Text('Camera', style: AppTextStyles.bodyMediumBold),
                onTap: () {
                  Get.back();
                  controller.pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
