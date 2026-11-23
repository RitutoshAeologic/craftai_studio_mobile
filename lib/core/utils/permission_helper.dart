import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';

/// Centralized permission and media access helper for CraftAI Studio.
/// Handles Camera, Gallery, and Microphone permissions gracefully across
/// iOS and Android, with custom dialogs when access is permanently denied.
class AppPermissionHelper {
  AppPermissionHelper._();

  /// Requests Camera permission if not yet granted.
  /// Shows an "Open Settings" dialog if permanently denied.
  /// Returns `true` if permission is granted, `false` otherwise.
  static Future<bool> ensureCameraPermission({BuildContext? context}) async {
    try {
      final status = await Permission.camera.status;

      if (status.isGranted || status.isLimited) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.camera.request();
        if (result.isGranted || result.isLimited) {
          return true;
        }
        if (result.isPermanentlyDenied) {
          if (context != null && !context.mounted) return false;
          showPermissionBlockedDialog(
            context: context,
            title: 'Camera Permission Blocked',
            message:
                'Camera access was permanently disabled for CraftAI Studio. Please enable it in Device Settings to capture reference portraits and photos.',
            icon: Icons.camera_alt_outlined,
          );
          return false;
        }
        _showNotice('Camera Permission', 'Camera access is required to take photos.');
        return false;
      }

      if (status.isPermanentlyDenied || status.isRestricted) {
        if (context != null && !context.mounted) return false;
        showPermissionBlockedDialog(
          context: context,
          title: 'Camera Permission Blocked',
          message:
              'Camera access is currently disabled for CraftAI Studio. Please enable it in Device Settings to take photos.',
          icon: Icons.camera_alt_outlined,
        );
        return false;
      }

      return false;
    } catch (e) {
      AppLogger.w('Camera permission check fallback: $e', tag: 'PERMISSION');
      // On some platforms or test environments, allow image_picker to handle system fallback
      return true;
    }
  }

  /// Safely picks an image from Camera or Gallery with end-to-end permission handling.
  /// Catches PlatformException (e.g. camera_access_denied / photo_access_denied)
  /// and shows the Settings redirect dialog if blocked.
  static Future<XFile?> pickImageSafely({
    required ImageSource source,
    BuildContext? context,
    ImagePicker? picker,
    int? imageQuality = 90,
    double? maxWidth,
    double? maxHeight,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
  }) async {
    final imagePicker = picker ?? ImagePicker();

    // If source is camera, check/request camera permission first
    if (source == ImageSource.camera) {
      final hasPermission = await ensureCameraPermission(context: context);
      if (!hasPermission) return null;
    }

    try {
      final picked = await imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        preferredCameraDevice: preferredCameraDevice,
      );
      return picked;
    } on PlatformException catch (e) {
      AppLogger.e('PlatformException during pickImage: [${e.code}] ${e.message}', tag: 'PERMISSION');

      final isCameraError = e.code == 'camera_access_denied' ||
          (e.message?.toLowerCase().contains('camera') ?? false);
      final isPhotoError = e.code == 'photo_access_denied' ||
          (e.message?.toLowerCase().contains('photo') ?? false);

      if (context != null && !context.mounted) return null;

      if (isCameraError) {
        showPermissionBlockedDialog(
          context: context,
          title: 'Camera Access Needed',
          message:
              'Camera permission was not granted. Please allow camera access in Device Settings to take reference photos.',
          icon: Icons.camera_alt_outlined,
        );
      } else if (isPhotoError) {
        showPermissionBlockedDialog(
          context: context,
          title: 'Photo Access Needed',
          message:
              'Photo library access was not granted. Please allow photo access in Device Settings to select pictures.',
          icon: Icons.photo_library_outlined,
        );
      } else {
        _showNotice('Photo Selection', e.message ?? 'Could not open camera or gallery.');
      }
      return null;
    } catch (e) {
      AppLogger.e('Unexpected error during pickImage: $e', tag: 'PERMISSION');
      _showNotice('Photo Selection', 'Could not access the selected photo.');
      return null;
    }
  }

  /// Displays a polished, branded modal dialog prompting the user to open system settings.
  static void showPermissionBlockedDialog({
    BuildContext? context,
    required String title,
    required String message,
    IconData icon = Icons.settings_outlined,
  }) {
    final targetContext = (context != null && context.mounted)
        ? context
        : (Get.overlayContext ?? Get.context);
    if (targetContext == null) {
      AppLogger.w('Cannot show permission dialog: no context available', tag: 'PERMISSION');
      return;
    }

    showDialog(
      context: targetContext,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          side: BorderSide(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.accentWarning.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accentWarning, size: 20.sp),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.h3.copyWith(fontSize: 16.sp),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.captionBold.copyWith(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSm),
              ),
            ),
            child: Text('Open Settings', style: AppTextStyles.captionBold),
          ),
        ],
      ),
    );
  }

  static void _showNotice(String title, String message) {
    if (Get.context != null && Get.overlayContext != null) {
      Get.snackbar(
        title,
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
