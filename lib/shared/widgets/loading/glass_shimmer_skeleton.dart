import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';

/// [GlassShimmerSkeleton] renders an animated specular light sweep across frosted glass.
/// Replaces flat grey boxes with modern frosted placeholders during image and data loading.
class GlassShimmerSkeleton extends StatefulWidget {
  const GlassShimmerSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  State<GlassShimmerSkeleton> createState() => _GlassShimmerSkeletonState();
}

class _GlassShimmerSkeletonState extends State<GlassShimmerSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = widget.borderRadius ?? BorderRadius.circular(12.r);
    final base = widget.baseColor ?? AppColors.surfaceLight;
    final highlight = widget.highlightColor ?? Colors.white.withValues(alpha: 0.15);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: effectiveRadius,
            gradient: LinearGradient(
              begin: Alignment(-1.5 + 3.0 * _controller.value, -0.3),
              end: Alignment(-0.5 + 3.0 * _controller.value, 0.3),
              colors: [
                base,
                highlight,
                base,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            border: Border.all(
              color: AppColors.glassBorderSubtle,
              width: 1.0.w,
            ),
          ),
        );
      },
    );
  }
}

