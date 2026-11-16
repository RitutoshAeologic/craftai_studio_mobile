import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../interactions/bouncy_tap.dart';

/// [ZoomableImageLightbox] is a dedicated, full-screen image viewer supporting:
/// - Smooth pinch-to-zoom (up to 5.0x) via [InteractiveViewer]
/// - Double-tap to quick-zoom (toggles 1.0x <-> 3.0x centered on tap location)
/// - Vertical swipe-down to dismiss with dynamic background opacity fade
/// - Immersive mode toggle (tap to hide/show UI controls)
/// - Hero transition integration from thumbnails
/// - Action shortcuts: Close, Share, Download, Aspect Ratio badge
class ZoomableImageLightbox extends StatefulWidget {
  const ZoomableImageLightbox({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.title,
    this.subtitle,
    this.aspectRatioStr,
    this.onDownload,
    this.onShare,
  });

  /// Remote or cached image URL
  final String imageUrl;

  /// Optional Hero tag for transition animation
  final String? heroTag;

  /// Optional title displayed in header
  final String? title;

  /// Optional subtitle or model description
  final String? subtitle;

  /// Optional aspect ratio string (e.g. '16:9', '1:1')
  final String? aspectRatioStr;

  /// Optional download action callback
  final VoidCallback? onDownload;

  /// Optional share action callback
  final VoidCallback? onShare;

  /// Static helper to display the lightbox as a transparent full-screen route
  static Future<T?> show<T>({
    required BuildContext context,
    required String imageUrl,
    String? heroTag,
    String? title,
    String? subtitle,
    String? aspectRatioStr,
    VoidCallback? onDownload,
    VoidCallback? onShare,
  }) {
    HapticFeedback.lightImpact();
    return Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: ZoomableImageLightbox(
              imageUrl: imageUrl,
              heroTag: heroTag,
              title: title,
              subtitle: subtitle,
              aspectRatioStr: aspectRatioStr,
              onDownload: onDownload,
              onShare: onShare,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 250),
        reverseTransitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  @override
  State<ZoomableImageLightbox> createState() => _ZoomableImageLightboxState();
}

class _ZoomableImageLightboxState extends State<ZoomableImageLightbox>
    with SingleTickerProviderStateMixin {
  late final TransformationController _transformationController;
  late final AnimationController _animController;
  Animation<Matrix4>? _zoomAnimation;

  // Gesture tracking
  Offset _doubleTapPosition = Offset.zero;
  double _currentScale = 1.0;
  bool _showControls = true;

  // Swipe-to-dismiss physics
  double _dragOffsetY = 0.0;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        if (_zoomAnimation != null) {
          _transformationController.value = _zoomAnimation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    if ((scale - _currentScale).abs() > 0.02) {
      setState(() {
        _currentScale = scale;
      });
    }
  }

  void _animateTransformation(Matrix4 target) {
    _zoomAnimation = Matrix4Tween(
      begin: _transformationController.value,
      end: target,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward(from: 0.0);
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _handleDoubleTap() {
    HapticFeedback.selectionClick();
    if (_currentScale > 1.1) {
      // Reset to 1.0x
      _animateTransformation(Matrix4.identity());
    } else {
      // Zoom to 3.0x focused on tapped point
      const double targetScale = 3.0;
      final double x = -_doubleTapPosition.dx * (targetScale - 1);
      final double y = -_doubleTapPosition.dy * (targetScale - 1);

      final targetMatrix = Matrix4(
        targetScale, 0.0, 0.0, 0.0,
        0.0, targetScale, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        x, y, 0.0, 1.0,
      );

      _animateTransformation(targetMatrix);
    }
  }

  void _handleSingleTap() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    if (_currentScale <= 1.05) {
      _isDragging = true;
    }
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffsetY += details.delta.dy;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0.0;
    // Dismiss if dragged down far enough or flicked with downwards velocity
    if (_dragOffsetY > 110 || velocity > 700) {
      Navigator.of(context).pop();
    } else {
      // Snap back to center
      setState(() {
        _dragOffsetY = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic background opacity during drag dismiss
    final double dragFraction = (_dragOffsetY.abs() / 320.0).clamp(0.0, 1.0);
    final double bgOpacity = (1.0 - dragFraction * 0.75).clamp(0.0, 1.0);
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    Widget imageContent = CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Colors.white,
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, size: 48.sp, color: Colors.white54),
            SizedBox(height: 8.h),
            Text(
              'Unable to load high-res image',
              style: AppTextStyles.caption.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );

    if (widget.heroTag != null) {
      imageContent = Hero(
        tag: widget.heroTag!,
        child: imageContent,
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: bgOpacity),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // =================================================================
            // MAIN INTERACTIVE VIEWER & GESTURES
            // =================================================================
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _handleSingleTap,
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              onVerticalDragStart: _currentScale <= 1.05 ? _onVerticalDragStart : null,
              onVerticalDragUpdate: _currentScale <= 1.05 ? _onVerticalDragUpdate : null,
              onVerticalDragEnd: _currentScale <= 1.05 ? _onVerticalDragEnd : null,
              child: Transform.translate(
                offset: Offset(0, _dragOffsetY),
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  clipBehavior: Clip.none,
                  child: Center(
                    child: imageContent,
                  ),
                ),
              ),
            ),

            // =================================================================
            // TOP CONTROLS OVERLAY (Close, Title, Actions)
            // =================================================================
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: _showControls ? topPadding + 8.h : -80.h,
              left: 16.w,
              right: 16.w,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: Row(
                  children: [
                    // Back / Close Button
                    BouncyTap(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        padding: EdgeInsets.all(10.w),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.20),
                            width: 1.w,
                          ),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 20.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Title & Subtitle or Aspect Ratio badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null && widget.title!.isNotEmpty)
                            Text(
                              widget.title!,
                              style: AppTextStyles.bodyMediumBold.copyWith(
                                color: Colors.white,
                                fontSize: 14.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                            Text(
                              widget.subtitle!,
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white70,
                                fontSize: 11.5.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),

                    // Aspect Ratio pill (if provided)
                    if (widget.aspectRatioStr != null && widget.aspectRatioStr!.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1.w,
                          ),
                        ),
                        child: Text(
                          widget.aspectRatioStr!,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],

                    // Share Action (if provided)
                    if (widget.onShare != null) ...[
                      BouncyTap(
                        onTap: widget.onShare,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.20),
                              width: 1.w,
                            ),
                          ),
                          child: Icon(
                            Icons.share_outlined,
                            size: 19.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],

                    // Download Action (if provided)
                    if (widget.onDownload != null)
                      BouncyTap(
                        onTap: widget.onDownload,
                        child: Container(
                          padding: EdgeInsets.all(10.w),
                          decoration: BoxDecoration(
                            gradient: AppColors.aiCosmicGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.40),
                                blurRadius: 10.r,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.download_rounded,
                            size: 19.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // =================================================================
            // BOTTOM CONTROLS & ZOOM INDICATOR
            // =================================================================
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              bottom: _showControls ? bottomPadding + 16.h : -80.h,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pinch_outlined,
                          size: 15.sp,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _currentScale > 1.05
                              ? '${_currentScale.toStringAsFixed(1)}x Zoom'
                              : 'Pinch or Double-Tap to Zoom',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (_currentScale > 1.05) ...[
                          SizedBox(width: 8.w),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _animateTransformation(Matrix4.identity());
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.20),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                'Reset',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
