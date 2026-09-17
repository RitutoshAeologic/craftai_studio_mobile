import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimens.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/network/api_config.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../domain/failures/studio_failure.dart';

/// [StudioErrorSheet] displays a user-friendly failure modal when generation
/// or prompt compilation fails.
///
/// Follows rules.md §6 error UX requirements:
/// 1. What happened (plain-language explanation)
/// 2. What to do next (retry / connection guidance)
/// 3. A way out (dismissible, non-blocking)
/// 4. Clear credit refund confirmation to reassure the user
class StudioErrorSheet extends StatelessWidget {
  const StudioErrorSheet({
    super.key,
    required this.failure,
    required this.refundedCredits,
    required this.onRetry,
  });

  final StudioFailure failure;
  final double refundedCredits;
  final VoidCallback onRetry;

  /// Convenience launcher to present the error modal.
  static void show({
    required StudioFailure failure,
    required double refundedCredits,
    required VoidCallback onRetry,
  }) {
    Get.bottomSheet(
      StudioErrorSheet(
        failure: failure,
        refundedCredits: refundedCredits,
        onRetry: onRetry,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isConnectionError = failure is StudioNetworkFailure || failure is StudioTimeoutFailure;
    final showAdbTip = isConnectionError && ApiConfig.isLocalHost && ApiConfig.isAndroidDevice;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusRound)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimens.spacingXl,
        AppDimens.spacingMd,
        AppDimens.spacingXl,
        AppDimens.spacingXxl,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Handle bar
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: AppDimens.vSpacingLg),

            // Icon + Title Header
            Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.h,
                  decoration: BoxDecoration(
                    color: AppColors.accentWarning.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  ),
                  child: Icon(
                    isConnectionError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                    color: AppColors.accentWarning,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: AppDimens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnectionError ? 'Server Connection Failed' : 'Generation Request Failed',
                        style: AppTextStyles.h3,
                      ),
                      SizedBox(height: AppDimens.vSpacingXxs),
                      Text(
                        'Your draft and selections were preserved',
                        style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            SizedBox(height: AppDimens.vSpacingLg),

            // Error Description Box
            Container(
              padding: EdgeInsets.all(AppDimens.spacingMd),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                failure.message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),

            SizedBox(height: AppDimens.vSpacingMd),

            // Credit Refund Confirmation Badge (Rules.md §2 & §6)
            if (refundedCredits > 0)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppDimens.spacingMd,
                  vertical: AppDimens.spacingSm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentSuccess.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.accentSuccess.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.accentSuccess,
                      size: 18.sp,
                    ),
                    SizedBox(width: AppDimens.spacingSm),
                    Expanded(
                      child: Text(
                        '✨ ${refundedCredits.toInt()} Credits have been refunded to your wallet balance.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.accentSuccess,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Optional Android ADB Reverse guidance
            if (showAdbTip) ...[
              SizedBox(height: AppDimens.vSpacingMd),
              Container(
                padding: EdgeInsets.all(AppDimens.spacingMd),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.terminal_rounded, size: 16.sp, color: AppColors.textSecondary),
                        SizedBox(width: 6.w),
                        Text(
                          'Local Device Tip',
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'If connecting your Android phone to a Mac server, run in terminal:\n'
                      'adb reverse tcp:8000 tcp:8000',
                      style: AppTextStyles.caption.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: AppDimens.vSpacingXl),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Dismiss',
                    isOutlined: true,
                    onPressed: () => Get.back(),
                  ),
                ),
                SizedBox(width: AppDimens.spacingMd),
                Expanded(
                  child: AppButton(
                    label: 'Retry',
                    icon: Icon(Icons.refresh_rounded, color: Colors.white, size: 18.sp),
                    onPressed: () {
                      Get.back();
                      onRetry();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  }
}
