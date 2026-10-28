import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import '../controllers/explore_controller.dart';
import 'more_like_this_sheet.dart';
import 'image_details_bottom_sheet.dart';
import '../../remix/views/remix_chat_view.dart';

/// Palette color item with color swatch and hex representation.
class _PaletteColor {
  final Color color;
  final String hex;

  const _PaletteColor(this.color, this.hex);
}

/// Static metadata model representing detailed AI generation parameters.
///
/// NOTE: Currently static UI data. Once the backend schema is integrated,
/// map these properties directly from [ExploreCardModel].
class _StaticImageMetadata {
  final String modelName;
  final String modelVersion;
  final String modelArchitecture;
  final String modelBadge;
  final String aspectRatio;
  final String resolution;
  final int steps;
  final double cfgScale;
  final String sampler;
  final String seed;
  final String clipSkip;
  final String negativePrompt;
  final String engine;
  final String renderTime;
  final String license;
  final List<String> tags;
  final List<_PaletteColor> palette;

  const _StaticImageMetadata({
    required this.modelName,
    required this.modelVersion,
    required this.modelArchitecture,
    required this.modelBadge,
    required this.aspectRatio,
    required this.resolution,
    required this.steps,
    required this.cfgScale,
    required this.sampler,
    required this.seed,
    required this.clipSkip,
    required this.negativePrompt,
    required this.engine,
    required this.renderTime,
    required this.license,
    required this.tags,
    required this.palette,
  });
}

class ExploreCardDetailSheet extends StatelessWidget {
  final ExploreCardModel card;
  const ExploreCardDetailSheet({super.key, required this.card});

  static void show(BuildContext context, ExploreCardModel card) {
    ImageDetailsBottomSheet.show(context, card);
  }

  /// Resolves realistic generation metadata based on the card's category/style.
  /// Replace with backend schema fields in [ExploreCardModel] once integrated.
  _StaticImageMetadata _resolveMetadata(ExploreCardModel card) {
    final cat = card.category.toLowerCase();
    if (cat.contains('cyberpunk')) {
      return const _StaticImageMetadata(
        modelName: 'FLUX.1 Pro',
        modelVersion: 'v1.1 Photoreal',
        modelArchitecture: 'Flow-Matching Transformer (12B Params)',
        modelBadge: 'Photoreal',
        aspectRatio: '1:1 Square',
        resolution: '1024 × 1024 px',
        steps: 35,
        cfgScale: 3.5,
        sampler: 'Euler Ancestral',
        seed: '849201948',
        clipSkip: '1',
        negativePrompt:
            'blurry, low quality, oversaturated, deformed anatomy, bad lighting, watermark, signature, extra fingers',
        engine: 'CraftAI Cloud GPU (FP16)',
        renderTime: '2.4s',
        license: 'CC-BY-NC 4.0 (Remix Allowed)',
        tags: ['Cyberpunk', 'Wet Asphalt', '85mm Bokeh', 'Neon Rain', 'Cinematic'],
        palette: [
          _PaletteColor(Color(0xFF0F172A), '#0F172A'),
          _PaletteColor(Color(0xFF06B6D4), '#06B6D4'),
          _PaletteColor(Color(0xFFEC4899), '#EC4899'),
          _PaletteColor(Color(0xFF8B5CF6), '#8B5CF6'),
          _PaletteColor(Color(0xFFF1F5F9), '#F1F5F9'),
        ],
      );
    } else if (cat.contains('photo') || cat.contains('portrait')) {
      return const _StaticImageMetadata(
        modelName: 'Google Gemini Imagen 3',
        modelVersion: 'Ultra-Fidelity v3.0',
        modelArchitecture: 'Deep Multimodal Diffusion Model',
        modelBadge: 'Ultra-HD',
        aspectRatio: '1:1 Square',
        resolution: '1024 × 1024 px',
        steps: 40,
        cfgScale: 4.0,
        sampler: 'FlowMatch Euler',
        seed: '918274635',
        clipSkip: '1',
        negativePrompt:
            'plastic skin, airbrushed, cartoon, oversaturated, bad hands, blurry eyes, distortion, text, watermark',
        engine: 'Cloud TPU v5e (TensorRT)',
        renderTime: '3.1s',
        license: 'CC-BY 4.0 (Commercial & Remix)',
        tags: ['Portrait', 'Hasselblad 100c', 'Golden Hour', 'Natural Light', 'Hyperrealism'],
        palette: [
          _PaletteColor(Color(0xFF1C1917), '#1C1917'),
          _PaletteColor(Color(0xFF78350F), '#78350F'),
          _PaletteColor(Color(0xFFD97706), '#D97706'),
          _PaletteColor(Color(0xFFFDE68A), '#FDE68A'),
          _PaletteColor(Color(0xFFFAFAF9), '#FAFAF9'),
        ],
      );
    } else if (cat.contains('anime')) {
      return const _StaticImageMetadata(
        modelName: 'Niji Anime v6',
        modelVersion: 'v6.0 Expressive',
        modelArchitecture: 'Latent Anime Diffusion Fine-Tune',
        modelBadge: 'Anime Core',
        aspectRatio: '1:1 Square',
        resolution: '1024 × 1024 px',
        steps: 28,
        cfgScale: 7.0,
        sampler: 'DPM++ 2M Karras',
        seed: '492018371',
        clipSkip: '2',
        negativePrompt:
            'worst quality, normal quality, low quality, bad anatomy, deformed eyes, extra limbs, mutation, watermark',
        engine: 'CraftAI Anime Core v2',
        renderTime: '1.9s',
        license: 'CC-BY-NC 4.0 (Remix Allowed)',
        tags: ['Anime', 'Mecha Armor', 'Celestial Glow', 'Makoto Shinkai', 'Dynamic'],
        palette: [
          _PaletteColor(Color(0xFF1E1B4B), '#1E1B4B'),
          _PaletteColor(Color(0xFF6366F1), '#6366F1'),
          _PaletteColor(Color(0xFF38BDF8), '#38BDF8'),
          _PaletteColor(Color(0xFFF472B6), '#F472B6'),
          _PaletteColor(Color(0xFFEDE9FE), '#EDE9FE'),
        ],
      );
    } else if (cat.contains('product')) {
      return const _StaticImageMetadata(
        modelName: 'FLUX.1 [dev]',
        modelVersion: 'v1.0 Guidance-Distilled',
        modelArchitecture: 'Flow-Matching Transformer (12B Params)',
        modelBadge: 'Studio 3D',
        aspectRatio: '1:1 Square',
        resolution: '1024 × 1024 px',
        steps: 32,
        cfgScale: 3.5,
        sampler: 'Euler A',
        seed: '518392014',
        clipSkip: '1',
        negativePrompt:
            'bad reflections, blurry, cartoon, low poly, noisy, distorted bevels, low resolution, watermark',
        engine: 'Octane Raytracing Simulator',
        renderTime: '2.6s',
        license: 'CC-BY 4.0 (Commercial & Remix)',
        tags: ['Product Design', 'Volumetric Rim', 'Studio Pedestal', 'Matte Black', 'Minimalist'],
        palette: [
          _PaletteColor(Color(0xFF18181B), '#18181B'),
          _PaletteColor(Color(0xFF27272A), '#27272A'),
          _PaletteColor(Color(0xFF71717A), '#71717A'),
          _PaletteColor(Color(0xFFA1A1AA), '#A1A1AA'),
          _PaletteColor(Color(0xFFFFFFFF), '#FFFFFF'),
        ],
      );
    } else if (cat.contains('3d') || cat.contains('character')) {
      return const _StaticImageMetadata(
        modelName: 'FLUX.1 Pro',
        modelVersion: 'v1.1 Unreal Engine 5 Style',
        modelArchitecture: 'Flow-Matching Transformer',
        modelBadge: 'Character 3D',
        aspectRatio: '1:1 Square',
        resolution: '1024 × 1024 px',
        steps: 36,
        cfgScale: 3.5,
        sampler: 'FlowMatch Euler',
        seed: '629104825',
        clipSkip: '1',
        negativePrompt:
            'blurry, distorted face, low poly, bad textures, deformed hands, poor lighting, watermark',
        engine: 'CraftAI GPU Cluster • FP16',
        renderTime: '2.5s',
        license: 'CC-BY-NC 4.0 (Remix Allowed)',
        tags: ['3D Character', 'Subsurface Scattering', 'Raytracing', 'Armor', 'Hyper-detailed'],
        palette: [
          _PaletteColor(Color(0xFF172554), '#172554'),
          _PaletteColor(Color(0xFF1E3A8A), '#1E3A8A'),
          _PaletteColor(Color(0xFF3B82F6), '#3B82F6'),
          _PaletteColor(Color(0xFF93C5FD), '#93C5FD'),
          _PaletteColor(Color(0xFFF0F9FF), '#F0F9FF'),
        ],
      );
    } else {
      return const _StaticImageMetadata(
        modelName: 'FLUX.1 Pro',
        modelVersion: 'v1.1 Master Edition',
        modelArchitecture: 'Flow-Matching Transformer (12B Params)',
        modelBadge: 'Ultra HD',
        aspectRatio: '1:1 Square',
        resolution: '1024 × 1024 px',
        steps: 30,
        cfgScale: 3.5,
        sampler: 'FlowMatch Euler',
        seed: '729401826',
        clipSkip: '1',
        negativePrompt:
            'blurry, distorted, low quality, low resolution, bad anatomy, deformed hands, watermark',
        engine: 'CraftAI Neural Engine v3',
        renderTime: '2.2s',
        license: 'CC-BY 4.0 (Remix Allowed)',
        tags: ['Masterpiece', 'High Detail', 'Volumetric Light', 'Aesthetic', 'Fine Art'],
        palette: [
          _PaletteColor(Color(0xFF262626), '#262626'),
          _PaletteColor(Color(0xFF52525B), '#52525B'),
          _PaletteColor(Color(0xFF94A3B8), '#94A3B8'),
          _PaletteColor(Color(0xFFCBD5E1), '#CBD5E1'),
          _PaletteColor(Color(0xFFFFFFFF), '#FFFFFF'),
        ],
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied! 📋',
      '$label copied to clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.primary,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ExploreController controller = Get.find<ExploreController>();
    final _StaticImageMetadata metadata = _resolveMetadata(card);

    return Container(
      constraints: BoxConstraints(maxHeight: 0.90.sh),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pill Handle
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.symmetric(vertical: 10.h),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  ),
                ),
              ),

              // Large High-Res Image Preview
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: CachedNetworkImage(
                          imageUrl: card.previewUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.surfaceLight,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceLight,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.palette_outlined, size: 36.r, color: AppColors.textMuted),
                                  SizedBox(height: 8.h),
                                  Text(
                                    card.title,
                                    style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Category & Model Badges
                    Positioned(
                      top: 12.h,
                      left: 12.w,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: Text(
                              card.category,
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.bolt_rounded, size: 12.sp, color: AppColors.orangeAccent),
                                SizedBox(width: 3.w),
                                Text(
                                  metadata.modelName,
                                  style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Like Button
                    Positioned(
                      top: 12.h,
                      right: 12.w,
                      child: Obx(() {
                        final currentCard = controller.cards.firstWhere(
                          (c) => c.id == card.id,
                          orElse: () => card,
                        );
                        return GestureDetector(
                          onTap: () => controller.toggleLike(card.id),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentCard.isLiked ? Icons.favorite : Icons.favorite_border,
                                  color: currentCard.isLiked ? AppColors.accentError : AppColors.white,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  '${currentCard.likeCount}',
                                  style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Royalty Split
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            card.title,
                            style: AppTextStyles.h2.copyWith(fontSize: 18.sp),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                          decoration: BoxDecoration(
                            color: AppColors.accentSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: Text(
                            '${(card.creatorRoyaltyCut / card.remixFee * 100).toInt()}% Royalty',
                            style: AppTextStyles.captionBold.copyWith(color: AppColors.accentSuccess),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),

                    // Author info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 12.r,
                          backgroundImage: CachedNetworkImageProvider(card.authorAvatar),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          card.authorName,
                          style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 13.sp),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          card.authorHandle,
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                        const Spacer(),
                        Text(
                          '${card.remixCount} remixes',
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),

                    Divider(color: AppColors.border, height: 24.h),

                    // Prompt Recipe Box Header with Copy Action
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Prompt Recipe',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => _copyToClipboard(card.maskedSummary, 'Prompt recipe'),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy_rounded, size: 12.sp, color: AppColors.textMuted),
                              SizedBox(width: 4.w),
                              Text(
                                'Copy',
                                style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        card.maskedSummary,
                        style: AppTextStyles.bodyMedium.copyWith(fontSize: 12.sp),
                      ),
                    ),

                    SizedBox(height: 16.h),

                    // =========================================================
                    // MEIGEN DUAL-ACTION BUTTONS ROW
                    // =========================================================
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.back();
                              controller.useAsPrompt(card);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.surface,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                            ),
                            icon: Icon(Icons.auto_awesome, size: 16.sp, color: AppColors.white),
                            label: Text(
                              'Use as Prompt',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.white),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Get.back();
                              controller.useAsRef(card);
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.border),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                              ),
                            ),
                            icon: Icon(Icons.photo_library_outlined, size: 16.sp, color: AppColors.primary),
                            label: Text(
                              'Use as Ref',
                              style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),

                    Divider(color: AppColors.border, height: 28.h),

                    // =========================================================
                    // IMAGE SPECIFICATIONS & AI GENERATION DETAILS
                    // =========================================================
                    _buildSectionHeader(),

                    SizedBox(height: 10.h),

                    // AI Model Engine Card
                    _buildModelCard(metadata),

                    SizedBox(height: 10.h),

                    // Generation Hyperparameters Matrix (2x3 Grid)
                    _buildParametersGrid(metadata),

                    SizedBox(height: 10.h),

                    // Negative Prompt Card
                    _buildNegativePromptBox(metadata),

                    SizedBox(height: 10.h),

                    // Style Tags & Aesthetic Palette
                    _buildPaletteAndTags(metadata),

                    SizedBox(height: 10.h),

                    // Technical Pipeline & License Footer
                    _buildTechFooter(metadata),

                    Divider(color: AppColors.border, height: 28.h),

                    // =========================================================
                    // ADVANCED REMIX ACTIONS
                    // =========================================================
                    // "Remix in Lab (Chat)" Action
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.to(
                            () => const RemixChatView(),
                            arguments: {
                              'anchorImageUrl': card.previewUrl,
                              'sourceType': 'explore',
                              'remixedFromPromptId': card.id,
                              'initialPrompt': card.maskedSummary.replaceAll(' • [Secret Recipe Encrypted]', ''),
                              'authorName': card.authorName,
                              'royaltyPercent': (card.creatorRoyaltyCut / card.remixFee * 100).toInt(),
                            },
                            transition: Transition.rightToLeft,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.15),
                          foregroundColor: AppColors.purpleAccent,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 11.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            side: const BorderSide(color: AppColors.purpleAccent),
                          ),
                        ),
                        icon: Icon(Icons.shuffle_rounded, size: 16.sp, color: AppColors.purpleAccent),
                        label: Text(
                          '⚡ Remix in Lab (Chat)',
                          style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.purpleAccent),
                        ),
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // "Remix on My Photo" Action
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () {
                          Get.back();
                          controller.remixWithMyPhoto(card);
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.surfaceLight,
                          padding: EdgeInsets.symmetric(vertical: 10.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                            side: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        icon: Icon(Icons.face_retouching_natural, size: 16.sp, color: AppColors.orangeAccent),
                        label: Text(
                          '⚡ Remix on My Photo (Subject Lock)',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.orangeAccent),
                        ),
                      ),
                    ),

                    SizedBox(height: 12.h),

                    // More Like This (pgvector)
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          Get.back();
                          Get.bottomSheet(MoreLikeThisSheet(referenceCard: card));
                        },
                        icon: Icon(Icons.bubble_chart_outlined, size: 16.sp, color: AppColors.textMuted),
                        label: Text(
                          'Discover More Like This (pgvector)',
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Section Header with title and AI Metadata badge.
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Icon(Icons.tune_rounded, size: 15.sp, color: AppColors.textPrimary),
        SizedBox(width: 6.w),
        Text(
          'Image Specifications',
          style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 13.sp),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusXs),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 10.sp, color: AppColors.orangeAccent),
              SizedBox(width: 3.w),
              Text(
                'AI Metadata',
                style: AppTextStyles.captionXs.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Highlights the generation engine / diffusion model used to produce the image.
  Widget _buildModelCard(_StaticImageMetadata metadata) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            ),
            child: Center(
              child: Icon(Icons.bolt_rounded, size: 20.sp, color: AppColors.white),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      metadata.modelName,
                      style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 13.sp),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                      decoration: BoxDecoration(
                        color: AppColors.orangeAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                      ),
                      child: Text(
                        metadata.modelBadge,
                        style: AppTextStyles.captionXs.copyWith(
                          color: AppColors.orangeAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                Text(
                  '${metadata.modelVersion} • ${metadata.modelArchitecture}',
                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2x3 Grid of generation parameters (Dimensions, Steps, Guidance, Sampler, Seed, Clip Skip).
  Widget _buildParametersGrid(_StaticImageMetadata metadata) {
    return Column(
      children: [
        Row(
          children: [
            _buildParameterTile(
              icon: Icons.aspect_ratio_rounded,
              label: 'Dimensions',
              value: metadata.resolution,
              secondaryValue: '(${metadata.aspectRatio.split(' ').first})',
            ),
            SizedBox(width: 8.w),
            _buildParameterTile(
              icon: Icons.linear_scale_rounded,
              label: 'Sampling Steps',
              value: '${metadata.steps} Steps',
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _buildParameterTile(
              icon: Icons.track_changes_rounded,
              label: 'Guidance (CFG)',
              value: '${metadata.cfgScale}',
            ),
            SizedBox(width: 8.w),
            _buildParameterTile(
              icon: Icons.scatter_plot_rounded,
              label: 'Sampler',
              value: metadata.sampler,
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            _buildParameterTile(
              icon: Icons.tag_rounded,
              label: 'Seed',
              value: metadata.seed,
              onCopy: () => _copyToClipboard(metadata.seed, 'Seed'),
            ),
            SizedBox(width: 8.w),
            _buildParameterTile(
              icon: Icons.skip_next_rounded,
              label: 'Clip Skip',
              value: metadata.clipSkip,
            ),
          ],
        ),
      ],
    );
  }

  /// Compact parameter tile displaying icon, label, value, and optional copy action.
  Widget _buildParameterTile({
    required IconData icon,
    required String label,
    required String value,
    String? secondaryValue,
    VoidCallback? onCopy,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimens.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: AppColors.textSecondary),
            SizedBox(width: 8.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          style: AppTextStyles.captionBold.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (secondaryValue != null) ...[
                        SizedBox(width: 3.w),
                        Text(
                          secondaryValue,
                          style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (onCopy != null)
              GestureDetector(
                onTap: onCopy,
                child: Padding(
                  padding: EdgeInsets.only(left: 4.w),
                  child: Icon(Icons.copy_rounded, size: 12.sp, color: AppColors.textMuted),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Negative prompt card with one-click copy button.
  Widget _buildNegativePromptBox(_StaticImageMetadata metadata) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
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
                  Icon(Icons.remove_circle_outline_rounded, size: 12.sp, color: AppColors.textMuted),
                  SizedBox(width: 4.w),
                  Text(
                    'Negative Prompt',
                    style: AppTextStyles.captionBold.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => _copyToClipboard(metadata.negativePrompt, 'Negative prompt'),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy_rounded, size: 12.sp, color: AppColors.textMuted),
                    SizedBox(width: 3.w),
                    Text(
                      'Copy',
                      style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            metadata.negativePrompt,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Style tags & interactive aesthetic color palette.
  Widget _buildPaletteAndTags(_StaticImageMetadata metadata) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Style Tags
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: metadata.tags.map((tag) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '#$tag',
                style: AppTextStyles.captionXs.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 8.h),

        // Dominant Color Palette
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Text(
                'Dominant Palette',
                style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
              ),
              const Spacer(),
              Row(
                children: metadata.palette.map((item) {
                  return GestureDetector(
                    onTap: () => _copyToClipboard(item.hex, 'Color ${item.hex}'),
                    child: Container(
                      margin: EdgeInsets.only(left: 6.w),
                      width: 18.r,
                      height: 18.r,
                      decoration: BoxDecoration(
                        color: item.color,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.08),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Technical Engine pipeline & Licensing details footer.
  Widget _buildTechFooter(_StaticImageMetadata metadata) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.speed_rounded, size: 12.sp, color: AppColors.textMuted),
              SizedBox(width: 4.w),
              Text(
                '${metadata.renderTime} render • ${metadata.engine.split(' ').first}',
                style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.verified_user_outlined, size: 12.sp, color: AppColors.accentSuccess),
              SizedBox(width: 4.w),
              Text(
                metadata.license.split(' ').first,
                style: AppTextStyles.captionXs.copyWith(color: AppColors.accentSuccess),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
