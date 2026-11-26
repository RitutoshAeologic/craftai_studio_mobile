import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import '../domain/models/poster_layout_model.dart';

/// Phase 3 normalized 0.0–1.0 interactive poster canvas preview using
/// [InteractiveViewer] + [CustomPainter] matching backend Pillow/CairoSVG export.
class PosterCanvasPreview extends StatefulWidget {
  final PosterLayoutTemplate layout;
  final String aspectRatio;
  final String topic;
  final String? headline;
  final String? subtext;
  final String? discountBadge;
  final String? imagePath;

  const PosterCanvasPreview({
    super.key,
    required this.layout,
    required this.aspectRatio,
    required this.topic,
    this.headline,
    this.subtext,
    this.discountBadge,
    this.imagePath,
  });

  @override
  State<PosterCanvasPreview> createState() => _PosterCanvasPreviewState();
}

class _PosterCanvasPreviewState extends State<PosterCanvasPreview> {
  ui.Image? _decodedLocalImage;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _loadLocalImageIfNeeded();
  }

  @override
  void didUpdateWidget(covariant PosterCanvasPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath) {
      _loadLocalImageIfNeeded();
    }
  }

  Future<void> _loadLocalImageIfNeeded() async {
    final path = widget.imagePath;
    if (path == null || path.isEmpty || path.startsWith('http')) {
      if (_decodedLocalImage != null && mounted) {
        setState(() {
          _decodedLocalImage = null;
          _loadedPath = null;
        });
      }
      return;
    }
    if (_loadedPath == path) return;
    _loadedPath = path;

    try {
      final file = File(path);
      if (!file.existsSync()) return;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted && _loadedPath == path) {
        setState(() {
          _decodedLocalImage = frame.image;
        });
      }
    } catch (_) {}
  }

  double _resolveRatio() {
    return switch (widget.aspectRatio) {
      '9:16' => 9 / 16,
      '1:1' => 1.0,
      '16:9' => 16 / 9,
      '4:5' || _ => 4 / 5,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _resolveRatio();
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.layers_outlined, size: 14.sp, color: AppColors.primary),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'Live Layout Preview',
                        style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Pinch to zoom',
                style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 140.h),
              child: AspectRatio(
                aspectRatio: ratio,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 3.0,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PosterLayoutPainter(
                        layout: widget.layout,
                        headlineText: (widget.headline?.trim().isNotEmpty ?? false)
                            ? widget.headline!.trim()
                            : (widget.topic.trim().isNotEmpty ? widget.topic.trim() : 'Your Headline'),
                        subtextText: (widget.subtext?.trim().isNotEmpty ?? false)
                            ? widget.subtext!.trim()
                            : '300 DPI Pillow + CairoSVG Export',
                        badgeText: widget.discountBadge?.trim(),
                        heroImage: _decodedLocalImage,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterLayoutPainter extends CustomPainter {
  final PosterLayoutTemplate layout;
  final String headlineText;
  final String subtextText;
  final String? badgeText;
  final ui.Image? heroImage;

  _PosterLayoutPainter({
    required this.layout,
    required this.headlineText,
    required this.subtextText,
    this.badgeText,
    this.heroImage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;

    // Background gradient
    final bgPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size.width, size.height),
        [layout.backgroundStart, layout.backgroundEnd],
      );
    canvas.drawRect(fullRect, bgPaint);

    for (final el in layout.elements) {
      final rect = Rect.fromLTWH(
        el.x * size.width,
        el.y * size.height,
        el.width * size.width,
        el.height * size.height,
      );
      final radius = Radius.circular(el.borderRadiusNorm * size.shortestSide);
      final rrect = RRect.fromRectAndRadius(rect, radius);

      switch (el.type) {
        case 'image':
          final slotPaint = Paint()
            ..color = el.backgroundColor ?? Colors.white.withValues(alpha: 0.08);
          canvas.drawRRect(rrect, slotPaint);
          if (heroImage != null) {
            canvas.save();
            canvas.clipRRect(rrect);
            final src = Rect.fromLTWH(
              0,
              0,
              heroImage!.width.toDouble(),
              heroImage!.height.toDouble(),
            );
            canvas.drawImageRect(heroImage!, src, rect, Paint()..filterQuality = FilterQuality.medium);
            canvas.restore();
          } else {
            _drawText(
              canvas,
              rect,
              'Featured Photo Slot',
              fontSize: size.height * 0.032,
              color: Colors.white.withValues(alpha: 0.45),
              align: TextAlign.center,
              weight: FontWeight.w500,
            );
          }
          break;

        case 'badge':
          final txt = (badgeText != null && badgeText!.isNotEmpty) ? badgeText! : el.text;
          if (txt == null || txt.isEmpty) break;
          if (el.backgroundColor != null) {
            canvas.drawRRect(rrect, Paint()..color = el.backgroundColor!);
          }
          _drawText(
            canvas,
            rect,
            txt,
            fontSize: size.height * el.fontSizeNorm,
            color: el.color,
            align: el.textAlign,
            weight: FontWeight.w800,
          );
          break;

        case 'headline':
          _drawText(
            canvas,
            rect,
            headlineText,
            fontSize: size.height * el.fontSizeNorm,
            color: el.color,
            align: el.textAlign,
            weight: FontWeight.w800,
            maxLines: 2,
          );
          break;

        case 'subtext':
          _drawText(
            canvas,
            rect,
            subtextText,
            fontSize: size.height * el.fontSizeNorm,
            color: el.color,
            align: el.textAlign,
            weight: FontWeight.w500,
            maxLines: 2,
          );
          break;

        case 'shape':
        default:
          if (el.backgroundColor != null) {
            canvas.drawRRect(rrect, Paint()..color = el.backgroundColor!);
          }
          break;
      }
    }
  }

  void _drawText(
    Canvas canvas,
    Rect rect,
    String text, {
    required double fontSize,
    required Color color,
    required TextAlign align,
    required FontWeight weight,
    int maxLines = 1,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize.clamp(8.0, 32.0),
          fontWeight: weight,
          height: 1.15,
        ),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: '…',
    )..layout(maxWidth: rect.width);

    final dy = rect.top + ((rect.height - tp.height) / 2).clamp(0.0, rect.height);
    double dx = rect.left;
    if (align == TextAlign.center) {
      dx = rect.left + ((rect.width - tp.width) / 2).clamp(0.0, rect.width);
    } else if (align == TextAlign.right) {
      dx = rect.right - tp.width;
    }
    tp.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(covariant _PosterLayoutPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.headlineText != headlineText ||
        oldDelegate.subtextText != subtextText ||
        oldDelegate.badgeText != badgeText ||
        oldDelegate.heroImage != heroImage;
  }
}
