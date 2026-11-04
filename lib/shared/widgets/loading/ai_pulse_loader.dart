import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// [AiPulseLoader] renders an iridescent, concentric glowing pulse animation for AI operations.
/// Replaces generic circular progress spinners with a high-end generative visual signature.
class AiPulseLoader extends StatefulWidget {
  const AiPulseLoader({
    super.key,
    this.message,
    this.size = 56.0,
    this.primaryColor,
    this.secondaryColor,
  });

  final String? message;
  final double size;
  final Color? primaryColor;
  final Color? secondaryColor;

  @override
  State<AiPulseLoader> createState() => _AiPulseLoaderState();
}

class _AiPulseLoaderState extends State<AiPulseLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? AppColors.primary;
    final secondary = widget.secondaryColor ?? AppColors.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: widget.size.w,
          height: widget.size.w,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _AiPulsePainter(
                  progress: _controller.value,
                  primaryColor: primary,
                  secondaryColor: secondary,
                ),
              );
            },
          ),
        ),
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          SizedBox(height: 14.h),
          Text(
            widget.message!,
            style: AppTextStyles.captionBold.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12.sp,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _AiPulsePainter extends CustomPainter {
  _AiPulsePainter({
    required this.progress,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final double progress;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw 3 expanding pulsing concentric ripples
    for (int i = 0; i < 3; i++) {
      final rippleProgress = (progress + (i * 0.33)) % 1.0;
      final radius = maxRadius * rippleProgress;
      final opacity = (1.0 - rippleProgress).clamp(0.0, 0.7);

      final paint = Paint()
        ..color = Color.lerp(primaryColor, secondaryColor, rippleProgress)!
            .withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0.w;

      canvas.drawCircle(center, radius, paint);
    }

    // Glowing core orb
    final coreGradient = RadialGradient(
      colors: [
        primaryColor,
        secondaryColor.withValues(alpha: 0.8),
      ],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: maxRadius * 0.35),
      );

    canvas.drawCircle(center, maxRadius * 0.35, corePaint);

    // Inner orbiting spark
    final sparkAngle = progress * 2 * math.pi;
    final sparkRadius = maxRadius * 0.55;
    final sparkOffset = Offset(
      center.dx + sparkRadius * math.cos(sparkAngle),
      center.dy + sparkRadius * math.sin(sparkAngle),
    );

    final sparkPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3);

    canvas.drawCircle(sparkOffset, 2.5.r, sparkPaint);
  }

  @override
  bool shouldRepaint(_AiPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

