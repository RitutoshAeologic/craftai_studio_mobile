import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// [LuminousMeshCanvas] renders a luxurious, ambient aurora background.
/// Provides soft, luminous organic light orbs (Violet, Cyan, Indigo) on top
/// of the porcelain canvas, giving physical depth and color for frosted
/// glass [BackdropFilter] widgets to catch and blur.
class LuminousMeshCanvas extends StatelessWidget {
  const LuminousMeshCanvas({
    super.key,
    required this.child,
    this.showOrbs = true,
  });

  final Widget child;
  final bool showOrbs;

  @override
  Widget build(BuildContext context) {
    if (!showOrbs) {
      return Container(
        color: AppColors.background,
        child: child,
      );
    }

    return Container(
      color: AppColors.background,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Ambient Orb 1 (Top-left Violet Glow)
          Positioned(
            top: -60,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.secondary.withValues(alpha: 0.14),
                      AppColors.secondary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ambient Orb 2 (Top-right Neon Cyan Glow)
          Positioned(
            top: 80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cyanAccent.withValues(alpha: 0.12),
                      AppColors.cyanAccent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Ambient Orb 3 (Center-left Indigo Glow)
          Positioned(
            bottom: 180,
            left: -40,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.10),
                      AppColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Screen Content
          child,
        ],
      ),
    );
  }
}

