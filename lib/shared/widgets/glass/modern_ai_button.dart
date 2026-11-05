import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../interactions/bouncy_tap.dart';

/// [ModernAiButton] is a tier-1 generative action button.
/// Features a cosmic AI gradient fill, top specular rim light,
/// tactile spring-scale tap physics via [BouncyTap], high-contrast visible loading state,
/// and duplicate request suppression while loading.
class ModernAiButton extends StatelessWidget {
  const ModernAiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.height,
    this.width,
    this.gradient,
    this.borderRadius,
    this.loadingMessage,
    this.loaderColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Widget? icon;
  final bool isOutlined;
  final double? height;
  final double? width;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final String? loadingMessage;
  final Color? loaderColor;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.h;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppDimens.radiusLg);
    final effectiveGradient = gradient ?? AppColors.aiCosmicGradient;

    // Genuinely disabled only when not in loading state and onPressed is null
    final isPureDisabled = onPressed == null && !isLoading;

    // High contrast color determination:
    // Solid gradient button uses crisp white spinner on cosmic gradient.
    // Outlined button uses primary color spinner on transparent/tinted surface.
    final effectiveLoaderColor = loaderColor ?? (isOutlined ? AppColors.primary : Colors.white);
    final effectiveLoaderTrackColor = effectiveLoaderColor.withValues(alpha: 0.28);
    final effectiveTextColor = isOutlined
        ? AppColors.primary
        : (isPureDisabled ? AppColors.textMuted : Colors.white);

    Widget buttonContent = Container(
      height: effectiveHeight,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        gradient: isOutlined
            ? null
            : (isPureDisabled ? null : effectiveGradient),
        color: isOutlined
            ? (isLoading ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent)
            : (isPureDisabled ? AppColors.surfaceLight : null),
        border: Border.all(
          color: isOutlined
              ? AppColors.primary
              : (isPureDisabled ? AppColors.border : Colors.white.withValues(alpha: 0.28)),
          width: 1.0.w,
        ),
        boxShadow: isPureDisabled || isOutlined
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: isLoading ? 0.45 : 0.35),
                  blurRadius: isLoading ? 20.r : 16.r,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Center(
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 18.w,
                    height: 18.w,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(effectiveLoaderColor),
                      backgroundColor: effectiveLoaderTrackColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Flexible(
                    child: Text(
                      loadingMessage ?? 'Processing with AI...',
                      style: AppTextStyles.button.copyWith(
                        color: effectiveTextColor,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    icon!,
                    SizedBox(width: 8.w),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      style: AppTextStyles.button.copyWith(
                        color: effectiveTextColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (isPureDisabled) {
      return Opacity(opacity: 0.55, child: buttonContent);
    }

    if (isLoading) {
      // While loading, block user interaction to prevent duplicate requests
      // Keep solid 100% opacity for high-contrast visible spinner and text
      return IgnorePointer(
        ignoring: true,
        child: buttonContent,
      );
    }

    return BouncyTap(
      onTap: onPressed,
      child: buttonContent,
    );
  }
}
