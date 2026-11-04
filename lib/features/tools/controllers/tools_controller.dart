import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/core/services/network_service.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/data/repositories/studio_repository_impl.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/shared/utils/reference_image_uploader.dart';

/// [ToolsController] drives the 6 MeiGen Skills Toolbox:
/// 1. ✂️ Remove Background (One tap, transparent PNG)
/// 2. 🖼️ AI Backgrounds (Swap backgrounds, your way)
/// 3. 📐 AI Expand (Extend your photo to any ratio)
/// 4. 🔍 Upscale 4K (Enlarge images & videos in HD)
/// 5. 🛍️ Product Detail Images (1 photo, full listing image set)
/// 6. 📢 Marketing Poster (Promos · events · hiring — one line in)
class ToolsController extends GetxController {
  final IStudioRepository _repository;

  ToolsController({IStudioRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<IStudioRepository>()
                ? Get.find<IStudioRepository>()
                : StudioRepositoryImpl());

  final ImagePicker _picker = ImagePicker();

  /// Active processing states
  final RxBool isProcessing = false.obs;
  final RxString processingMessage = ''.obs;

  /// Active input image path (local file or remote URL)
  final RxnString inputImagePath = RxnString();

  /// Active result image URL (e.g. transparent cutout PNG or generated image)
  final RxnString resultImageUrl = RxnString();

  /// Magic Grab dual-layer observables
  final RxnString magicGrabCutoutUrl = RxnString();
  final RxnString magicGrabBackgroundUrl = RxnString();

  /// E-Commerce 4-Pack results
  final Rxn<Map<String, dynamic>> productPackResults = Rxn<Map<String, dynamic>>();

  /// 6 Curated MeiGen Creative Skills
  final List<Map<String, dynamic>> tools = const [
    {
      'id': 'bg_remover',
      'title': 'Remove Background',
      'desc': 'One tap, transparent PNG',
      'icon': '✂️',
      'iconData': AppIcons.bgRemover,
      'badge': 'Zero-Token • Instant',
      'credits': '0 Cr',
      'cost': 0.0,
      'bgTint': Color(0xFF161B26),
      'accentColor': Color(0xFF10B981),
      'category': 'Edit',
    },
    {
      'id': 'magic_eraser',
      'title': 'Magic Object Eraser',
      'desc': 'Erase unwanted objects & text',
      'icon': '🪄',
      'iconData': AppIcons.magicEraser,
      'badge': 'Zero-Token • LaMa',
      'credits': '0 Cr',
      'cost': 0.0,
      'bgTint': Color(0xFF161B26),
      'accentColor': Color(0xFFA855F7),
      'category': 'Edit',
    },
    // [TEMPORARILY COMMENTED FOR PHASE 1]
    // {
    //   'id': 'magic_grab',
    //   'title': 'Magic Grab',
    //   'desc': 'Lift & reposition any object freely',
    //   'icon': '🖐️',
    //   'badge': 'Canva & Pixel Parity',
    //   'credits': '0 Cr',
    //   'cost': 0.0,
    //   'bgTint': Color(0xFFEDE7F6),
    //   'accentColor': Color(0xFF7E57C2),
    //   'category': 'Edit',
    // },
    {
      'id': 'photo_colorizer',
      'title': 'Vintage Photo Colorizer',
      'desc': 'Restore B&W photos to vivid color',
      'icon': '🎨',
      'iconData': AppIcons.photoColorizer,
      'badge': 'DDColor • Neural',
      'credits': '0 Cr',
      'cost': 0.0,
      'bgTint': Color(0xFF161B26),
      'accentColor': Color(0xFFF59E0B),
      'category': 'Edit',
    },
    {
      'id': 'ai_background',
      'title': 'AI Backgrounds',
      'desc': 'Swap backgrounds, your way',
      'icon': '🖼️',
      'iconData': AppIcons.aiBackgrounds,
      'badge': 'Pure White / Smart',
      'credits': '10 Cr',
      'cost': 10.0,
      'bgTint': Color(0xFF161B26),
      'accentColor': Color(0xFF6366F1),
      'category': 'Edit',
    },
    {
      'id': 'ai_expand',
      'title': 'AI Expand',
      'desc': 'Extend your photo to any ratio',
      'icon': '📐',
      'iconData': AppIcons.aiExpand,
      'badge': 'Multi-Ratio Outpaint',
      'credits': '10 Cr',
      'cost': 10.0,
      'bgTint': Color(0xFF161B26),
      'accentColor': Color(0xFF06B6D4),
      'category': 'Enhance',
    },
    {
      'id': 'upscaler',
      'title': 'Upscale 4K',
      'desc': 'Enlarge images & videos in HD',
      'icon': '🔍',
      'iconData': AppIcons.upscaler,
      'badge': 'Super Resolution',
      'credits': '2 Cr',
      'cost': 2.0,
      'bgTint': Color(0xFF161B26),
      'accentColor': Color(0xFF3B82F6),
      'category': 'Enhance',
    },
    // [TEMPORARILY COMMENTED FOR PHASE 1: Product Details, E-Commerce 4-Pack & Marketing Poster]
    // {
    //   'id': 'product_detail',
    //   'title': 'Product Detail Images',
    //   'desc': '1 photo, full listing image set',
    //   'icon': '🛍️',
    //   'badge': 'E-Commerce Set',
    //   'credits': '10 Cr',
    //   'cost': 10.0,
    //   'bgTint': Color(0xFFEBF0F8),
    //   'accentColor': Color(0xFF3949AB),
    //   'category': 'Transform',
    // },
    // {
    //   'id': 'product_pack',
    //   'title': 'E-Commerce 4-Pack',
    //   'desc': 'Amazon, Pedestal, Lifestyle & Story in 1 tap',
    //   'icon': '📦',
    //   'badge': 'Shopify & Amazon 4-in-1',
    //   'credits': '10 Cr',
    //   'cost': 10.0,
    //   'bgTint': Color(0xFFE0F2F1),
    //   'accentColor': Color(0xFF00897B),
    //   'category': 'Transform',
    // },
    // {
    //   'id': 'marketing_poster',
    //   'title': 'Marketing Poster',
    //   'desc': 'Promos · events · hiring — one line in',
    //   'icon': '📢',
    //   'badge': 'Commercial Copy',
    //   'credits': '10 Cr',
    //   'cost': 10.0,
    //   'bgTint': Color(0xFFE5EEFB),
    //   'accentColor': Color(0xFF1E88E5),
    //   'category': 'Transform',
    // },
  ];

  /// Available categories
  final List<String> categories = const ['all', 'Edit', 'Enhance'];
  final RxString selectedCategory = 'all'.obs;

  List<Map<String, dynamic>> get filteredTools {
    if (selectedCategory.value == 'all') return tools;
    return tools.where((t) => t['category'] == selectedCategory.value).toList();
  }

  void setCategory(String cat) {
    selectedCategory.value = cat;
  }

  /// Picks a photo from Gallery or Camera
  Future<File?> pickImage(ImageSource source) async {
    try {
      final xfile = await _picker.pickImage(source: source, imageQuality: 90);
      if (xfile != null) {
        final file = File(xfile.path);
        inputImagePath.value = file.path;
        resultImageUrl.value = null;
        return file;
      }
    } catch (e) {
      AppLogger.e('Error picking image: $e', tag: 'TOOLS');
      _showNotice('Photo Selection', 'Could not access selected photo.');
    }
    return null;
  }

  /// Safe snackbar dispatch that guards against headless test runners
  void _showNotice(String title, String message, {Color color = AppColors.accentWarning}) {
    if (Get.context != null && Get.overlayContext != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: color,
      );
    }
  }

  /// Helper to ensure image is a remote URL or data URI before API dispatch
  Future<String> _ensureRemoteUrl(String path) async {
    if (path.startsWith('http') || path.startsWith('data:')) return path;
    processingMessage.value = 'Uploading photo to secure gateway...';
    try {
      final upRes = await ReferenceImageUploader.uploadReferenceImage(File(path));
      if (upRes.url != null) {
        return upRes.url!;
      }
    } catch (e) {
      AppLogger.w('Gateway upload notice: $e. Encoding in-memory Data URI.', tag: 'TOOLS');
    }
    // Resilient fallback: Data URI
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        final ext = path.split('.').last.toLowerCase();
        final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
        final b64 = base64Encode(bytes);
        return 'data:$mime;base64,$b64';
      }
    } catch (_) {}
    throw Exception('Failed to prepare photo for processing.');
  }

  /// Pre-flight guard for connectivity and credits
  bool _preflightCheck({required double requiredCredits}) {
    if (Get.isRegistered<NetworkService>() && !NetworkService.to.isConnected.value) {
      _showNotice('Offline Mode', 'Internet connection required for AI skills processing.');
      return false;
    }

    if (Get.isRegistered<ShellController>()) {
      final shell = ShellController.to;
      if (requiredCredits > 0 && shell.userCredits.value < requiredCredits) {
        _showNotice(
          'Insufficient Credits',
          'You need at least ${requiredCredits.toStringAsFixed(0)} credits for this skill.',
        );
        return false;
      }
    }
    return true;
  }

  /// Skill 1: Remove Background
  Future<void> runBackgroundRemoval({String? directPath}) async {
    final path = directPath ?? inputImagePath.value;
    if (path == null) {
      _showNotice('Select Photo First', 'Please upload or select an image.');
      return;
    }
    if (!_preflightCheck(requiredCredits: 0.0)) return;

    isProcessing.value = true;
    processingMessage.value = 'Extracting transparent cutout with U2-Net ONNX...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.removeBackground(imageUrl: remoteUrl);
      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        AppLogger.s('Cutout generated: ${result.data!}', tag: 'TOOLS');
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: '1-tap transparent PNG cutout',
            credits: 0.0,
            previewUrl: result.data!,
            type: 'BG_REMOVAL',
            metadata: {'source_url': remoteUrl},
          );
        }
      } else {
        throw Exception(result.failure?.message ?? 'Failed to generate cutout');
      }
    } catch (e) {
      AppLogger.e('Error running background removal: $e', tag: 'TOOLS');
      _showNotice('Processing Notice', e.toString().replaceAll('Exception: ', ''));
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Skill 2: AI Backgrounds
  Future<String?> runAiBackground({
    required String path,
    required String mode,
    String? customBackdrop,
    String aspectRatio = 'Auto',
    String quality = '1k',
    bool harmonizeLighting = true,
  }) async {
    final cost = mode == 'pure_white' ? 0.0 : (quality == '1k' ? 10.0 : 14.0);
    if (!_preflightCheck(requiredCredits: cost)) return null;

    isProcessing.value = true;
    processingMessage.value = mode == 'pure_white'
        ? 'Compositing pure white cyclo studio background...'
        : 'Synthesizing contextual high-end studio scene...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.generateAiBackground(
        imageUrl: remoteUrl,
        mode: mode,
        customBackdrop: customBackdrop,
        aspectRatio: aspectRatio,
        quality: quality,
        harmonizeLighting: harmonizeLighting,
      );

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (cost > 0 && Get.isRegistered<ShellController>()) {
          ShellController.to.deductCredits(cost);
        }
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: mode == 'pure_white' ? 'Pure white studio backdrop' : 'AI Background ($mode)',
            credits: cost,
            previewUrl: result.data!,
            type: 'AI_BACKGROUND',
            metadata: {'mode': mode, 'source_url': remoteUrl},
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to generate AI background');
      }
    } catch (e) {
      AppLogger.e('Error in AI Backgrounds: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Skill 3: AI Expand
  Future<String?> runAiExpand({
    required String path,
    required String targetRatio,
    String quality = '1k',
    String alignment = 'auto',
    String? prompt,
    String engine = 'diffusion',
  }) async {
    final cost = quality == '1k' ? 10.0 : 14.0;
    if (!_preflightCheck(requiredCredits: cost)) return null;

    isProcessing.value = true;
    processingMessage.value = engine == 'diffusion'
        ? 'Generating scene expansion via FLUX ($targetRatio)...'
        : 'Extending canvas outpaint to $targetRatio...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.executeAiExpand(
        imageUrl: remoteUrl,
        targetRatio: targetRatio,
        quality: quality,
        alignment: alignment,
        prompt: prompt,
        engine: engine,
      );

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (Get.isRegistered<ShellController>()) {
          ShellController.to.deductCredits(cost);
        }
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: prompt != null && prompt.trim().isNotEmpty
                ? 'AI Expand ($targetRatio): ${prompt.trim()}'
                : 'AI Expand canvas ($targetRatio)',
            credits: cost,
            previewUrl: result.data!,
            type: 'AI_EXPAND',
            metadata: {
              'target_ratio': targetRatio,
              'source_url': remoteUrl,
              'alignment': alignment,
              'engine': engine,
            },
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to expand image');
      }
    } catch (e) {
      AppLogger.e('Error in AI Expand: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Skill 4: Upscale 4K
  Future<String?> runUpscale({
    required String path,
    int scaleFactor = 2,
  }) async {
    const cost = 2.0;
    if (!_preflightCheck(requiredCredits: cost)) return null;

    isProcessing.value = true;
    processingMessage.value = 'Running 4K super-resolution enhancement...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.upscaleImage(imageUrl: remoteUrl, scaleFactor: scaleFactor);

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (Get.isRegistered<ShellController>()) {
          ShellController.to.deductCredits(cost);
        }
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: '4K Super-resolution master',
            credits: cost,
            previewUrl: result.data!,
            type: 'UPSCALE_4K',
            metadata: {'scale_factor': scaleFactor, 'source_url': remoteUrl},
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to upscale image');
      }
    } catch (e) {
      AppLogger.e('Error in Upscale 4K: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Skill 5: Product Detail Images
  Future<String?> runProductDetail({
    String? path,
    String productName = 'Commercial Product',
    String aspectRatio = '4:5',
    String language = 'Auto',
    String quality = '1k',
  }) async {
    final cost = quality == '1k' ? 10.0 : 14.0;
    if (!_preflightCheck(requiredCredits: cost)) return null;

    isProcessing.value = true;
    processingMessage.value = 'Generating e-commerce listing set for "$productName"...';
    try {
      String? remoteUrl;
      if (path != null && path.trim().isNotEmpty) {
        remoteUrl = await _ensureRemoteUrl(path);
      }
      final result = await _repository.executeProductDetail(
        imageUrl: remoteUrl,
        productName: productName,
        aspectRatio: aspectRatio,
        language: language,
        quality: quality,
      );

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (Get.isRegistered<ShellController>()) {
          ShellController.to.deductCredits(cost);
        }
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: 'Product Listing: $productName',
            credits: cost,
            previewUrl: result.data!,
            type: 'PRODUCT_DETAIL',
            metadata: {
              'product_name': productName,
              if (remoteUrl != null) 'source_url': remoteUrl,
              'quality': quality,
            },
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to generate product details');
      }
    } catch (e) {
      AppLogger.e('Error in Product Detail: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Skill 6: Marketing Poster
  Future<String?> runMarketingPoster({
    required String topic,
    String? path,
    String category = 'Promotion',
    String aspectRatio = '4:5',
    String? headline,
    String? subtext,
    String? discountBadge,
    String? theme,
    String language = 'Auto',
    String quality = '1k',
  }) async {
    final cost = quality == '1k' ? 10.0 : 14.0;
    if (!_preflightCheck(requiredCredits: cost)) return null;

    isProcessing.value = true;
    processingMessage.value = 'Designing commercial poster for "$topic"...';
    try {
      String? remoteUrl;
      if (path != null && path.trim().isNotEmpty) {
        remoteUrl = await _ensureRemoteUrl(path);
      }

      final result = await _repository.generateMarketingPoster(
        topic: topic,
        imageUrl: remoteUrl,
        category: category,
        aspectRatio: aspectRatio,
        headline: headline,
        subtext: subtext,
        discountBadge: discountBadge,
        theme: theme,
        language: language,
        quality: quality,
      );

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (Get.isRegistered<ShellController>()) {
          ShellController.to.deductCredits(cost);
        }
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: 'Marketing Poster: $topic',
            credits: cost,
            previewUrl: result.data!,
            type: 'MARKETING_POSTER',
            metadata: {
              'topic': topic,
              'category': category,
              'headline': headline,
              if (remoteUrl != null) 'source_url': remoteUrl,
            },
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to generate poster');
      }
    } catch (e) {
      AppLogger.e('Error in Marketing Poster: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Skill 7: Magic Object Eraser (Zero-Hallucination LaMa Inpainting)
  Future<String?> runObjectErase({
    required String path,
    required String maskBase64,
  }) async {
    isProcessing.value = true;
    processingMessage.value = 'Erasing object with LaMa neural inpainting...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.eraseObject(
        imageUrl: remoteUrl,
        maskBase64: maskBase64,
      );

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: 'Magic Object Eraser Inpainting',
            credits: 0.0,
            previewUrl: result.data!,
            type: 'OBJECT_ERASER',
            metadata: {'source_url': remoteUrl},
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to erase object');
      }
    } catch (e) {
      AppLogger.e('Error in Magic Object Eraser: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Skill 8: Vintage Photo Colorizer (DDColor Neural Restorer)
  Future<String?> runPhotoColorize({
    required String path,
    double saturation = 1.2,
  }) async {
    isProcessing.value = true;
    processingMessage.value = 'Restoring authentic colors with DDColor...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.colorizePhoto(
        imageUrl: remoteUrl,
        saturation: saturation,
      );

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: 'Vintage Photo Colorizer (${saturation}x saturation)',
            credits: 0.0,
            previewUrl: result.data!,
            type: 'PHOTO_COLORIZER',
            metadata: {'source_url': remoteUrl, 'saturation': saturation},
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to colorize photo');
      }
    } catch (e) {
      AppLogger.e('Error in Photo Colorizer: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Magic Grab (Canva Magic Grab & Pixel Magic Editor parity)
  Future<Map<String, dynamic>?> runMagicGrab({
    required String path,
    required String maskBase64,
  }) async {
    isProcessing.value = true;
    processingMessage.value = 'Extracting cutout and synthesizing background plate...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.executeMagicGrab(
        imageUrl: remoteUrl,
        maskBase64: maskBase64,
      );

      if (result.data != null && result.data!['cutout_url'] != null) {
        final cutout = result.data!['cutout_url'] as String;
        final bgPlate = result.data!['background_url'] as String? ??
            result.data!['clean_background_url'] as String? ??
            remoteUrl;
        magicGrabCutoutUrl.value = cutout;
        magicGrabBackgroundUrl.value = bgPlate;
        resultImageUrl.value = cutout;

        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: 'Magic Grab Subject Cutout',
            credits: 0.0,
            previewUrl: cutout,
            type: 'MAGIC_GRAB',
            metadata: {
              'source_url': remoteUrl,
              'cutout_url': cutout,
              'background_url': bgPlate,
            },
          );
        }
        return result.data;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to execute Magic Grab');
      }
    } catch (e) {
      AppLogger.e('Error in Magic Grab: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// E-Commerce 4-Pack Auto-Listing Generator (Shopify Magic / Photoroom Pro parity)
  Future<Map<String, dynamic>?> runProductPack({
    String? path,
    String productName = 'Commercial Product',
  }) async {
    const cost = 10.0;
    if (!_preflightCheck(requiredCredits: cost)) return null;

    isProcessing.value = true;
    processingMessage.value = 'Generating 4 marketplace listings (Amazon, Studio, Lifestyle, Story)...';
    try {
      String? remoteUrl;
      if (path != null && path.trim().isNotEmpty) {
        remoteUrl = await _ensureRemoteUrl(path);
      }

      final result = await _repository.executeProductPack(
        imageUrl: remoteUrl,
        productName: productName,
      );

      if (result.data != null) {
        final data = result.data!;
        final pack = (data['pack'] as Map<String, dynamic>?) ?? {
          'amazon_white': data['amazon_white_url'] as String? ?? '',
          'studio_pedestal': data['studio_pedestal_url'] as String? ?? '',
          'lifestyle_table': data['lifestyle_table_url'] as String? ?? '',
          'story_flyer': data['story_flyer_url'] as String? ?? '',
        };
        final normalizedData = {
          ...data,
          'pack': pack,
        };
        productPackResults.value = normalizedData;
        final firstUrl = pack['amazon_white'] as String? ?? pack['studio_pedestal'] as String? ?? '';
        resultImageUrl.value = firstUrl;

        if (Get.isRegistered<ShellController>()) {
          ShellController.to.deductCredits(cost);
        }
        if (Get.isRegistered<LibraryController>() && firstUrl.isNotEmpty) {
          LibraryController.to.addNewCreation(
            prompt: 'E-Commerce 4-Pack: $productName',
            credits: cost,
            previewUrl: firstUrl,
            type: 'PRODUCT_PACK',
            metadata: {
              'product_name': productName,
              if (remoteUrl != null) 'source_url': remoteUrl,
              'pack': pack,
            },
          );
        }
        return normalizedData;
      } else {
        throw Exception(result.failure?.message ?? 'Failed to generate product pack');
      }
    } catch (e) {
      AppLogger.e('Error in Product Pack: $e', tag: 'TOOLS');
      _showNotice('Notice', e.toString().replaceAll('Exception: ', ''));
      return null;
    } finally {
      isProcessing.value = false;
      processingMessage.value = '';
    }
  }

  /// Resets active input/result
  void clearActiveSession() {
    inputImagePath.value = null;
    resultImageUrl.value = null;
    magicGrabCutoutUrl.value = null;
    magicGrabBackgroundUrl.value = null;
    productPackResults.value = null;
    isProcessing.value = false;
  }
}

