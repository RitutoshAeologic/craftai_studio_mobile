import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'app_network_image.dart';

/// [BeforeAfterSlider] is a high-performance, gesture-driven split image
/// comparison widget. Designed to be reused across Studio (Remix), AI Tools,
/// and Cloud Library per rules.md §5.
class BeforeAfterSlider extends StatefulWidget {
  final String beforeImageUrl;
  final String afterImageUrl;
  final double height;
  final double initialPosition;
  final String beforeLabel;
  final String afterLabel;

  const BeforeAfterSlider({
    super.key,
    required this.beforeImageUrl,
    required this.afterImageUrl,
    this.height = 280,
    this.initialPosition = 0.50,
    this.beforeLabel = 'ANCHOR',
    this.afterLabel = 'REMIX',
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  late double _clipFraction;
  bool _isHoldingOriginal = false;

  @override
  void initState() {
    super.initState();
    _clipFraction = widget.initialPosition.clamp(0.05, 0.95);
  }

  void _handleDrag(DragUpdateDetails details, double boxWidth) {
    if (boxWidth <= 0) return;
    setState(() {
      _clipFraction = (_clipFraction + details.primaryDelta! / boxWidth).clamp(0.02, 0.98);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final splitX = width * (_isHoldingOriginal ? 1.0 : _clipFraction);

        return Container(
          height: widget.height.h,
          width: width,
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusMd),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Bottom Layer: After (Remix) Image
                _buildCachedImage(widget.afterImageUrl),

                // 2. Top Layer: Before (Anchor) Image clipped to splitX
                if (!_isHoldingOriginal)
                  ClipRect(
                    clipper: _HorizontalSplitClipper(splitX),
                    child: _buildCachedImage(widget.beforeImageUrl),
                  )
                else
                  _buildCachedImage(widget.beforeImageUrl),

                // 3. Badges (Top Left & Top Right)
                Positioned(
                  top: 10.h,
                  left: 10.w,
                  child: _buildBadge(widget.beforeLabel, AppColors.surface.withValues(alpha: 0.8)),
                ),
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: _buildBadge(widget.afterLabel, AppColors.primary.withValues(alpha: 0.9)),
                ),

                // 4. Center Split Divider Line & Drag Handle
                if (!_isHoldingOriginal) ...[
                  Positioned(
                    left: splitX - 1.w,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2.w,
                      color: Colors.white,
                    ),
                  ),
                  Positioned(
                    left: splitX - 16.w,
                    top: (widget.height.h / 2) - 16.h,
                    child: GestureDetector(
                      onHorizontalDragUpdate: (d) => _handleDrag(d, width),
                      child: Container(
                        width: 32.w,
                        height: 32.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_left, size: 14.sp, color: Colors.black),
                              Icon(Icons.arrow_right, size: 14.sp, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // 5. Full-width Gesture Detector for touch drag across entire image
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragUpdate: (d) => _handleDrag(d, width),
                    onLongPressStart: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _isHoldingOriginal = true);
                    },
                    onLongPressEnd: (_) {
                      setState(() => _isHoldingOriginal = false);
                    },
                  ),
                ),

                // 6. Bottom Hold Hint
                Positioned(
                  bottom: 8.h,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.60),
                        borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      ),
                      child: Text(
                        _isHoldingOriginal ? 'Viewing Anchor' : 'Drag divider or hold to view original',
                        style: AppTextStyles.captionXs.copyWith(
                          color: Colors.white70,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCachedImage(String url) {
    if (url.isEmpty) {
      return Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 32.sp),
        ),
      );
    }
    return AppNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.zero,
      width: double.infinity,
      height: double.infinity,
      errorWidget: Container(
        color: AppColors.surfaceLight,
        child: Center(
          child: Icon(Icons.broken_image, color: AppColors.textMuted, size: 32.sp),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color bg) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTextStyles.captionXs.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _HorizontalSplitClipper extends CustomClipper<Rect> {
  final double splitX;

  _HorizontalSplitClipper(this.splitX);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, splitX, size.height);
  }

  @override
  bool shouldReclip(covariant _HorizontalSplitClipper oldClipper) {
    return oldClipper.splitX != splitX;
  }
}
