import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/shared/widgets/interactions/bouncy_tap.dart';

/// Single item within the [ExpandableNavigationFab] menu.
class FabMenuItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const FabMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });
}

/// An expandable Floating Action Button with an upward cascade menu.
/// Features smooth spring animations, frosted glass backdrop, outside tap dismissal,
/// and back button collapse support.
class ExpandableNavigationFab extends StatefulWidget {
  final List<FabMenuItem> items;
  final double bottomOffset;

  const ExpandableNavigationFab({
    super.key,
    required this.items,
    this.bottomOffset = 82.0,
  });

  @override
  State<ExpandableNavigationFab> createState() => ExpandableNavigationFabState();
}

class ExpandableNavigationFabState extends State<ExpandableNavigationFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  late final Animation<double> _rotateAnimation;
  late final Animation<double> _fadeAnimation;

  bool _isExpanded = false;
  bool get isExpanded => _isExpanded;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );

    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInCubic,
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.125).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void toggle() {
    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _controller.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _expandAnimation.value;
        final isMenuVisible = progress > 0.001;

        return Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // Full-screen dismiss barrier when menu is expanded
            if (isMenuVisible)
              Positioned.fill(
                child: GestureDetector(
                  onTap: collapse,
                  behavior: HitTestBehavior.opaque,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 6.0 * progress,
                          sigmaY: 6.0 * progress,
                        ),
                        child: Container(
                          color: Colors.black.withValues(alpha: 0.38 * progress),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Expanded menu items column
            if (isMenuVisible)
              Positioned(
                bottom: widget.bottomOffset + 60.h,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1.0).animate(_expandAnimation),
                    alignment: Alignment.bottomCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 0.65,
                      ),
                      child: SingleChildScrollView(
                        clipBehavior: Clip.none,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(widget.items.length, (idx) {
                            final item = widget.items[idx];
                            return _buildMenuItem(item, idx, widget.items.length);
                          }),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // The main Trigger FAB button
            Positioned(
              bottom: widget.bottomOffset,
              child: Tooltip(
                message: 'Create & AI Tools',
                child: BouncyTap(
                  key: const ValueKey('expandable_nav_fab_trigger'),
                  onTap: toggle,
                  child: Container(
                    width: 52.w,
                    height: 52.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.aiCosmicGradient,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                        width: 1.5.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          blurRadius: 16.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: RotationTransition(
                        turns: _rotateAnimation,
                        child: Icon(
                          _isExpanded ? Icons.close_rounded : Icons.auto_awesome_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItem(FabMenuItem item, int index, int total) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: BouncyTap(
        key: ValueKey('fab_item_${item.title}'),
        onTap: () {
          collapse();
          item.onTap();
        },
        child: Container(
          width: 250.w,
          constraints: BoxConstraints(minHeight: 48.h),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: AppColors.glassDarkSurface,
            borderRadius: BorderRadius.circular(AppDimens.radiusRound),
            border: Border.all(
              color: AppColors.glassBorderSubtle,
              width: 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 12.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.accentColor.withValues(alpha: 0.16),
                ),
                child: Center(
                  child: Icon(item.icon, color: item.accentColor, size: 17.sp),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.subtitle,
                      style: AppTextStyles.captionXs.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 9.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11.sp,
                color: AppColors.textMuted,
              ),
              SizedBox(width: 4.w),
            ],
          ),
        ),
      ),
    );
  }
}
