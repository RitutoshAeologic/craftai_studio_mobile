import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';

/// [GlassContainer] is a hardware-accelerated frosted glass container.
/// Applies an optical [BackdropFilter] blur with a specular gradient border
/// and a translucent glass surface sheen, mimicking modern iOS and Apple design.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.blur = 16.0,
    this.opacity = 0.08,
    this.tintColor,
    this.borderRadius,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.border,
    this.borderGradient,
    this.shadows,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final Color? tintColor;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxBorder? border;
  final Gradient? borderGradient;
  final List<BoxShadow>? shadows;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppDimens.radiusLg);
    final effectiveTintColor = tintColor ?? AppColors.glassSurface;

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveTintColor,
        borderRadius: effectiveRadius,
        border: border ??
            Border.all(
              color: AppColors.glassBorder,
              width: 1.0.w,
            ),
      ),
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: shadows ??
            [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 16.r,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      ),
    );
  }
}
