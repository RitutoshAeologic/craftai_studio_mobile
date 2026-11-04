import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../interactions/bouncy_tap.dart';

/// [ModernAiButton] is a tier-1 generative action button.
/// Features a cosmic AI gradient fill, top specular rim light,
/// tactile spring-scale tap physics via [BouncyTap], and fluid loading state.
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

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.h;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppDimens.radiusLg);
    final effectiveGradient = gradient ?? AppColors.aiCosmicGradient;
    final isDisabled = onPressed == null || isLoading;

    Widget buttonContent = Container(
      height: effectiveHeight,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        gradient: isOutlined
            ? null
            : (isDisabled ? null : effectiveGradient),
        color: isOutlined
            ? Colors.transparent
            : (isDisabled ? AppColors.surfaceLight : null),
        border: Border.all(
          color: isOutlined
              ? AppColors.primary
              : Colors.white.withValues(alpha: 0.22),
          width: 1.0.w,
        ),
        boxShadow: isDisabled || isOutlined
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16.r,
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
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    loadingMessage ?? 'Processing with AI...',
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 13.sp,
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
                  Text(
                    label,
                    style: AppTextStyles.button.copyWith(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );

    if (isDisabled) {
      return Opacity(opacity: 0.65, child: buttonContent);
    }

    return BouncyTap(
      onTap: onPressed,
      child: buttonContent,
    );
  }
}

