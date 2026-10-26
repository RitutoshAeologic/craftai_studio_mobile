import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../shell/controllers/shell_controller.dart';
import '../../wallet/views/wallet_view.dart';

/// [ProfileController] manages user profile state, session information,
/// and profile actions (clipboard copying, wallet navigation, sign out).
class ProfileController extends GetxController {
  static ProfileController get to => Get.find<ProfileController>();

  /// Access to global [AuthController]
  AuthController get authController => Get.find<AuthController>();

  /// Access to global [ShellController]
  ShellController get shellController => Get.find<ShellController>();

  /// Direct Supabase current user safely handling mock or uninitialized states
  User? get supabaseUser {
    try {
      return SupabaseService.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// User email address
  String get email =>
      authController.currentUser.value?.email ??
      supabaseUser?.email ??
      'Creator Account';

  /// User display name or fallback derived from email
  String get displayName {
    final customName = authController.currentUser.value?.displayName;
    if (customName != null && customName.trim().isNotEmpty) {
      return customName.trim();
    }
    final metaName = supabaseUser?.userMetadata?['display_name'] as String?;
    if (metaName != null && metaName.trim().isNotEmpty) {
      return metaName.trim();
    }
    if (email.contains('@')) {
      final handle = email.split('@').first;
      return handle.isNotEmpty
          ? '${handle[0].toUpperCase()}${handle.substring(1)}'
          : 'Creator';
    }
    return 'Creator';
  }

  /// Unique user UUID
  String get userId =>
      authController.currentUser.value?.id ?? supabaseUser?.id ?? 'Unknown ID';

  /// Truncated representation of user ID for clean presentation
  String get maskedUserId {
    final id = userId;
    if (id.length > 12) {
      return '${id.substring(0, 8)}...${id.substring(id.length - 4)}';
    }
    return id;
  }

  /// Whether the user has confirmed their email address
  bool get isEmailConfirmed =>
      authController.currentUser.value?.isEmailConfirmed ??
      (supabaseUser?.emailConfirmedAt != null);

  /// Formatted account creation date string
  String get memberSinceFormatted {
    final createdAtStr = supabaseUser?.createdAt;
    if (createdAtStr != null) {
      final dt = DateTime.tryParse(createdAtStr);
      if (dt != null) {
        return DateFormat('MMM dd, yyyy').format(dt);
      }
    }
    return 'Active Creator';
  }

  /// Copies text to clipboard and displays an informative snackbar
  Future<void> copyToClipboard(String text, String label) async {
    await Clipboard.setData(ClipboardData(text: text));
    AppLogger.d('Copied $label to clipboard', tag: 'PROFILE');
    Get.snackbar(
      '$label Copied 📋',
      text,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.surface,
      colorText: AppColors.textPrimary,
      borderColor: AppColors.border,
      borderWidth: 1,
      borderRadius: 12.r,
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      duration: const Duration(seconds: 2),
    );
  }

  /// Navigates directly to the full Wallet view
  void openWallet() {
    Get.to(() => const WalletView());
  }

  /// Prompts user with sign-out confirmation dialog and executes sign-out
  void confirmSignOut() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Sign Out?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of CraftAI Studio?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () {
              Get.back();
              if (Get.isRegistered<AuthController>()) {
                Get.find<AuthController>().signOut();
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
