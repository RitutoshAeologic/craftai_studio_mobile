import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

/// [GlassBottomSheet] provides a frosted glass container for modal bottom sheets.
/// Applies [BackdropFilter] blur, specular top border, rounded top corners,
/// and a centered drag handle pill.
class GlassBottomSheet extends StatelessWidget {
  const GlassBottomSheet({
    super.key,
    required this.child,
    this.maxHeightFactor = 0.88,
    this.showDragHandle = true,
  });

  final Widget child;
  final double maxHeightFactor;
  final bool showDragHandle;

  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double maxHeightFactor = 0.88,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.60),
      builder: (_) => GlassBottomSheet(
        maxHeightFactor: maxHeightFactor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: maxHeightFactor,
      child: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassDarkSurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border(
                top: BorderSide(color: AppColors.glassBorder, width: 1.2.w),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                  blurRadius: 24.r,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDragHandle) ...[
                  SizedBox(height: 10.h),
                  Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withValues(alpha: 0.30),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],
                Expanded(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
