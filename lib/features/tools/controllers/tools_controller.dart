import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  /// 6 Curated MeiGen Creative Skills
  final List<Map<String, dynamic>> tools = const [
    {
      'id': 'bg_remover',
      'title': 'Remove Background',
      'desc': 'One tap, transparent PNG',
      'icon': '✂️',
      'badge': 'Zero-Token • Instant',
      'credits': '0 Cr',
      'cost': 0.0,
      'bgTint': Color(0xFFEAF1ED),
      'accentColor': Color(0xFF2E7D32),
      'category': 'Edit',
    },
    {
      'id': 'ai_background',
      'title': 'AI Backgrounds',
      'desc': 'Swap backgrounds, your way',
      'icon': '🖼️',
      'badge': 'Pure White / Smart',
      'credits': '10 Cr',
      'cost': 10.0,
      'bgTint': Color(0xFFF5EFE6),
      'accentColor': Color(0xFF8D6E63),
      'category': 'Edit',
    },
    {
      'id': 'ai_expand',
      'title': 'AI Expand',
      'desc': 'Extend your photo to any ratio',
      'icon': '📐',
      'badge': 'Multi-Ratio Outpaint',
      'credits': '10 Cr',
      'cost': 10.0,
      'bgTint': Color(0xFFEBEBFA),
      'accentColor': Color(0xFF5C6BC0),
      'category': 'Enhance',
    },
    {
      'id': 'upscaler',
      'title': 'Upscale 4K',
      'desc': 'Enlarge images & videos in HD',
      'icon': '🔍',
      'badge': 'Super Resolution',
      'credits': '2 Cr',
      'cost': 2.0,
      'bgTint': Color(0xFFE6EFF5),
      'accentColor': Color(0xFF0288D1),
      'category': 'Enhance',
    },
    {
      'id': 'product_detail',
      'title': 'Product Detail Images',
      'desc': '1 photo, full listing image set',
      'icon': '🛍️',
      'badge': 'E-Commerce Set',
      'credits': '10 Cr',
      'cost': 10.0,
      'bgTint': Color(0xFFEBF0F8),
      'accentColor': Color(0xFF3949AB),
      'category': 'Transform',
    },
    {
      'id': 'marketing_poster',
      'title': 'Marketing Poster',
      'desc': 'Promos · events · hiring — one line in',
      'icon': '📢',
      'badge': 'Commercial Copy',
      'credits': '10 Cr',
      'cost': 10.0,
      'bgTint': Color(0xFFE5EEFB),
      'accentColor': Color(0xFF1E88E5),
      'category': 'Transform',
    },
  ];

  /// Available categories
  final List<String> categories = const ['all', 'Edit', 'Enhance', 'Transform'];
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

  /// Helper to ensure image is a remote URL before API dispatch
  Future<String> _ensureRemoteUrl(String path) async {
    if (path.startsWith('http')) return path;
    processingMessage.value = 'Uploading photo to secure gateway...';
    final upRes = await ReferenceImageUploader.uploadReferenceImage(File(path));
    if (upRes.url == null) {
      throw Exception(upRes.failure?.message ?? 'Failed to upload photo for processing');
    }
    return upRes.url!;
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
  }) async {
    final cost = quality == '1k' ? 10.0 : 14.0;
    if (!_preflightCheck(requiredCredits: cost)) return null;

    isProcessing.value = true;
    processingMessage.value = 'Extending canvas outpaint to $targetRatio...';
    try {
      final remoteUrl = await _ensureRemoteUrl(path);
      final result = await _repository.executeAiExpand(
        imageUrl: remoteUrl,
        targetRatio: targetRatio,
        quality: quality,
      );

      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        if (Get.isRegistered<ShellController>()) {
          ShellController.to.deductCredits(cost);
        }
        if (Get.isRegistered<LibraryController>()) {
          LibraryController.to.addNewCreation(
            prompt: 'AI Expand canvas ($targetRatio)',
            credits: cost,
            previewUrl: result.data!,
            type: 'AI_EXPAND',
            metadata: {'target_ratio': targetRatio, 'source_url': remoteUrl},
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

  /// Resets active input/result
  void clearActiveSession() {
    inputImagePath.value = null;
    resultImageUrl.value = null;
    isProcessing.value = false;
  }
}

