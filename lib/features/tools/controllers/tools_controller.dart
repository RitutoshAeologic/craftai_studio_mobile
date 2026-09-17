import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/data/repositories/studio_repository_impl.dart';
import 'package:craftai_studio_mobile/shared/utils/reference_image_uploader.dart';

/// [ToolsController] drives the MeiGen Creative Skills Toolbox:
/// - ✂️ AI Background Remover (Zero-Token local CPU rembg)
/// - 🔍 4K Lossless Upscaler
/// - 💡 Studio Relighting & Bokeh
/// - 🎭 Face Swap & Identity Lock (InstantID)
/// - 🎬 AI Video & LivePortrait Motion
class ToolsController extends GetxController {
  final IStudioRepository _repository;

  ToolsController({IStudioRepository? repository})
      : _repository = repository ??
            (Get.isRegistered<IStudioRepository>()
                ? Get.find<IStudioRepository>()
                : StudioRepositoryImpl());

  final ImagePicker _picker = ImagePicker();

  /// Currently selected category ('all', 'Edit', 'Enhance', 'Transform', 'Motion')
  final RxString selectedCategory = 'all'.obs;

  /// Active processing states
  final RxBool isProcessing = false.obs;
  final RxString processingMessage = ''.obs;

  /// Active input image path (local file or remote URL)
  final RxnString inputImagePath = RxnString();

  /// Active result image URL (e.g. transparent cutout PNG)
  final RxnString resultImageUrl = RxnString();

  /// Curated tool catalog matching MeiGen creative skills
  final List<Map<String, dynamic>> tools = const [
    {
      'id': 'bg_remover',
      'title': 'AI Background Remover',
      'desc': '1-tap transparent PNG cutout powered by local U2-Net ONNX. 100% Free & Zero-Token.',
      'icon': '✂️',
      'badge': 'Zero-Token • Instant',
      'credits': '0 Cr',
      'gradient': [Color(0xFF00F5D4), Color(0xFF0EA5E9)],
      'category': 'Edit',
    },
    {
      'id': 'upscaler',
      'title': '4K Lossless Upscaler',
      'desc': 'Super-resolution detail restoration. Boost micro-textures and clarity up to 4096px.',
      'icon': '🔍',
      'badge': 'Super Resolution',
      'credits': '1 Cr',
      'gradient': [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      'category': 'Enhance',
    },
    {
      'id': 'relighting',
      'title': 'Portrait Relighting & Bokeh',
      'desc': 'Depth-map studio relighting with Rembrandt lighting, rim highlights, and f/1.2 blur.',
      'icon': '💡',
      'badge': 'DSLR Optics',
      'credits': '2 Cr',
      'gradient': [Color(0xFFFFB703), Color(0xFFF43F5E)],
      'category': 'Enhance',
    },
    {
      'id': 'faceswap',
      'title': 'Face Swap & Identity Lock',
      'desc': 'InstantID facial landmark lock. Reconstruct user identity onto any aesthetic scene.',
      'icon': '🎭',
      'badge': 'InstantID',
      'credits': '2 Cr',
      'gradient': [Color(0xFF06B6D4), Color(0xFF3B82F6)],
      'category': 'Transform',
    },
    {
      'id': 'video_motion',
      'title': 'AI Video & Face Motion',
      'desc': 'LivePortrait face motion (Smile, Wink, Talk, Nod) and cinematic camera sweeps.',
      'icon': '🎬',
      'badge': 'LivePortrait',
      'credits': '5 Cr',
      'gradient': [Color(0xFF10B981), Color(0xFF06B6D4)],
      'category': 'Motion',
    },
  ];

  /// Available categories
  final List<String> categories = const ['all', 'Edit', 'Enhance', 'Transform', 'Motion'];

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
      Get.snackbar(
        'Photo Selection',
        'Could not access selected photo.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
    }
    return null;
  }

  /// Executes AI Background Removal on the current [inputImagePath]
  Future<void> runBackgroundRemoval({String? directPath}) async {
    final path = directPath ?? inputImagePath.value;
    if (path == null) {
      Get.snackbar(
        'Select Photo First',
        'Please upload or select an image to remove its background.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
      return;
    }

    isProcessing.value = true;
    processingMessage.value = 'Preparing image for local CPU extraction...';
    try {
      String remoteUrl = path;
      if (!path.startsWith('http')) {
        processingMessage.value = 'Uploading photo to gateway...';
        final upRes = await ReferenceImageUploader.uploadReferenceImage(File(path));
        if (upRes.url == null) {
          throw Exception(upRes.failure?.message ?? 'Failed to upload photo for processing');
        }
        remoteUrl = upRes.url!;
      }

      processingMessage.value = 'Extracting transparent cutout with U2-Net ONNX...';
      final result = await _repository.removeBackground(imageUrl: remoteUrl);
      if (result.data != null && result.data!.isNotEmpty) {
        resultImageUrl.value = result.data!;
        AppLogger.s('Cutout successfully generated: ${result.data!}', tag: 'TOOLS');
        Get.snackbar(
          '✂️ Background Removed!',
          'Clean transparent PNG cutout ready (Zero tokens used).',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.surface,
          colorText: AppColors.accentSuccess,
          duration: const Duration(seconds: 3),
        );
      } else {
        throw Exception(result.failure?.message ?? 'Failed to generate cutout');
      }
    } catch (e) {
      AppLogger.e('Error running background removal: $e', tag: 'TOOLS');
      Get.snackbar(
        'Processing Notice',
        e.toString().replaceAll('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
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
