import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';
import '../../core/constants/app_text_styles.dart';

/// [AppButton] is a shared, enterprise-grade action button component.
/// Mandated by rules.md §5 to prevent inline button duplication.
///
/// Features:
/// - Supports solid primary fill or subtle outline
/// - Built-in circular loading indicator state with zero layout shift
/// - Custom leading icon support
/// - Standard Obsidian corner rounding & typography
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.height,
    this.width,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
  });

  /// Button label text.
  final String label;

  /// Callback executed when the button is tapped. Disabled if null or [isLoading] is true.
  final VoidCallback? onPressed;

  /// Whether the button displays a loading spinner instead of the label/icon.
  final bool isLoading;

  /// Optional leading icon.
  final Widget? icon;

  /// Whether to render an outlined style rather than solid background.
  final bool isOutlined;

  /// Button height override (defaults to 48.h).
  final double? height;

  /// Button width override (defaults to double.infinity).
  final double? width;

  /// Background color override.
  final Color? backgroundColor;

  /// Text/icon color override.
  final Color? foregroundColor;

  /// Corner radius override.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveHeight = height ?? 48.h;
    final effectiveRadius = borderRadius ?? AppDimens.radiusLg;

    final effectiveBg = backgroundColor ??
        (isOutlined ? Colors.transparent : AppColors.primary);
    final effectiveFg = foregroundColor ??
        (isOutlined ? AppColors.primary : AppColors.white);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(effectiveRadius),
      side: isOutlined
          ? BorderSide(color: AppColors.primary.withValues(alpha: 0.6), width: 1.w)
          : BorderSide.none,
    );

    final childContent = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16.w,
            height: 16.w,
            child: CircularProgressIndicator(
              color: effectiveFg,
              strokeWidth: 2,
            ),
          ),
          SizedBox(width: 8.w),
        ] else if (icon != null) ...[
          icon!,
          SizedBox(width: 6.w),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.buttonLarge.copyWith(
              color: effectiveFg,
            ),
          ),
        ),
      ],
    );

    return SizedBox(
      width: width ?? double.infinity,
      height: effectiveHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          shape: shape,
          elevation: 0,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: childContent,
      ),
    );
  }
}
