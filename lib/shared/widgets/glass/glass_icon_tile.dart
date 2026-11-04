import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

/// [GlassIconTile] renders a precision vector icon inside an iridescent frosted glass tile.
/// Eliminates raw unicode emojis across the UI with consistent modern geometry and specular rim lighting.
class GlassIconTile extends StatelessWidget {
  const GlassIconTile({
    super.key,
    required this.icon,
    this.size = 44.0,
    this.iconSize = 20.0,
    this.accentColor,
    this.iconColor,
    this.borderRadius,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final Color? accentColor;
  final Color? iconColor;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveAccent = accentColor ?? AppColors.primary;
    final effectiveRadius = borderRadius ?? 12.r;

    return Container(
      width: size.w,
      height: size.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            effectiveAccent.withValues(alpha: 0.16),
            effectiveAccent.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(
          color: effectiveAccent.withValues(alpha: 0.28),
          width: 1.0.w,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveAccent.withValues(alpha: 0.12),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: iconSize.sp,
          color: iconColor ?? effectiveAccent,
        ),
      ),
    );
  }
}
