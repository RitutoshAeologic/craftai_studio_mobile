import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/tool_result_preview_sheet.dart';

class DrawnStroke {
  final Path path;
  final double strokeWidth;

  DrawnStroke({required this.path, required this.strokeWidth});
}

class MagicObjectEraserView extends StatefulWidget {
  final String? initialImagePath;

  const MagicObjectEraserView({super.key, this.initialImagePath});

  @override
  State<MagicObjectEraserView> createState() => _MagicObjectEraserViewState();
}

class _MagicObjectEraserViewState extends State<MagicObjectEraserView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  String? _imagePath;
  ui.Image? _decodedImage;
  double _brushSize = 35.0;
  final List<DrawnStroke> _strokes = [];
  final List<DrawnStroke> _undoStack = [];
  Path? _currentPath;
  Offset? _currentCursorPosition;

  final GlobalKey _canvasKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    controller.clearActiveSession();
    _imagePath = widget.initialImagePath;
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      _loadImage(_imagePath!);
    }
  }

  @override
  void dispose() {
    controller.clearActiveSession();
    super.dispose();
  }

  Future<void> _loadImage(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final client = HttpClient();
        final request = await client.getUrl(Uri.parse(path));
        final response = await request.close();
        final byteList = await response.fold<List<int>>([], (prev, elem) => prev..addAll(elem));
        bytes = Uint8List.fromList(byteList);
      } else if (path.startsWith('data:')) {
        bytes = base64Decode(path.split(',').last);
      } else {
        bytes = await File(path).readAsBytes();
      }

      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _strokes.clear();
          _undoStack.clear();
        });
      }
    } catch (e) {
      Get.snackbar(
        'Photo Loading Error',
        'Could not load image for editing: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentWarning,
      );
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final file = await controller.pickImage(source);
    if (file != null) {
      setState(() {
        _imagePath = file.path;
      });
      await _loadImage(file.path);
    }
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _undoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_undoStack.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _strokes.add(_undoStack.removeLast());
    });
  }

  void _clearMask() {
    if (_strokes.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _strokes.clear();
      _undoStack.clear();
    });
  }

  /// Exports binary mask at native image resolution (#000000 base, #FFFFFF strokes).
  /// Mitigates Loophole 1 & 2 (coordinate distortion & mask polarity inversion).
  Future<String?> _generateMaskBase64(Size viewportSize) async {
    if (_decodedImage == null || _strokes.isEmpty) return null;

    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, imgW, imgH));

    // 1. Fill base with solid black (#000000 = PRESERVE)
    final bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, imgW, imgH), bgPaint);

    // 2. Compute exact scale & letterbox offsets from viewport
    final double scale = min(viewportSize.width / imgW, viewportSize.height / imgH);
    final double offsetX = (viewportSize.width - (imgW * scale)) / 2;
    final double offsetY = (viewportSize.height - (imgH * scale)) / 2;

    // 3. Paint strokes in solid white (#FFFFFF = ERASE)
    final maskPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in _strokes) {
      maskPaint.strokeWidth = stroke.strokeWidth / scale;

      // Transform path from viewport coordinate space to original image pixel coordinates
      final matrix = Matrix4.identity()
        // ignore: deprecated_member_use
        ..scale(1 / scale, 1 / scale)
        // ignore: deprecated_member_use
        ..translate(-offsetX, -offsetY);

      final transformedPath = stroke.path.transform(matrix.storage);
      canvas.drawPath(transformedPath, maskPaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(imgW.toInt(), imgH.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return 'data:image/png;base64,${base64Encode(byteData.buffer.asUint8List())}';
  }

  Future<void> _executeErase() async {
    if (_imagePath == null || _decodedImage == null) {
      Get.snackbar('Image Required', 'Please select a photo first.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    if (_strokes.isEmpty) {
      Get.snackbar('Mask Required 🪄', 'Brush over the object you want to erase.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final maskBase64 = await _generateMaskBase64(renderBox.size);
    if (maskBase64 == null) return;

    HapticFeedback.heavyImpact();
    final outUrl = await controller.runObjectErase(
      path: _imagePath!,
      maskBase64: maskBase64,
    );

    if (outUrl != null && mounted) {
      ToolResultPreviewSheet.show(
        context: context,
        title: 'Magic Object Eraser',
        resultImageUrl: outUrl,
        originalImageUrl: _imagePath,
        creditsUsed: 0.0,
        badgeText: 'Sub-Second Inpaint',
        enableBeforeAfter: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Magic Object Eraser', style: AppTextStyles.h2.copyWith(fontSize: 18.sp)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Canvas Viewport Area
            Expanded(
              child: Container(
                margin: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                  border: Border.all(color: AppColors.border),
                ),
                clipBehavior: Clip.antiAlias,
                child: _decodedImage == null
                    ? _buildEmptyState()
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            key: _canvasKey,
                            onPanStart: (details) {
                              final pos = details.localPosition;
                              _undoStack.clear();
                              _currentPath = Path()..moveTo(pos.dx, pos.dy);
                              _strokes.add(DrawnStroke(path: _currentPath!, strokeWidth: _brushSize));
                              setState(() {
                                _currentCursorPosition = pos;
                              });
                            },
                            onPanUpdate: (details) {
                              final pos = details.localPosition;
                              _currentPath?.lineTo(pos.dx, pos.dy);
                              setState(() {
                                _currentCursorPosition = pos;
                              });
                            },
                            onPanEnd: (_) {
                              setState(() {
                                _currentCursorPosition = null;
                                _currentPath = null;
                              });
                            },
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _EraserCanvasPainter(
                                      image: _decodedImage!,
                                      strokes: _strokes,
                                    ),
                                  ),
                                ),
                                if (_currentCursorPosition != null)
                                  Positioned(
                                    left: _currentCursorPosition!.dx - _brushSize / 2,
                                    top: _currentCursorPosition!.dy - _brushSize / 2,
                                    child: IgnorePointer(
                                      child: Container(
                                        width: _brushSize,
                                        height: _brushSize,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: const Color(0xFFC084FC), width: 2),
                                          color: const Color(0x33A855F7),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ),

            // Toolbar Controls Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brush Size Slider
                  Row(
                    children: [
                      Icon(Icons.brush, color: AppColors.textSecondary, size: 16.sp),
                      SizedBox(width: 8.w),
                      Text('Brush: ${_brushSize.toInt()}px',
                          style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: AppColors.surfaceLight,
                            thumbColor: AppColors.primary,
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 7.r),
                            trackHeight: 3.h,
                          ),
                          child: Slider(
                            value: _brushSize,
                            min: 10.0,
                            max: 80.0,
                            onChanged: (val) {
                              setState(() {
                                _brushSize = val;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8.h),

                  // Action Buttons: Undo, Redo, Clear
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.undo_rounded),
                                color: _strokes.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                                onPressed: _strokes.isNotEmpty ? _undo : null,
                                tooltip: 'Undo',
                              ),
                              IconButton(
                                icon: const Icon(Icons.redo_rounded),
                                color: _undoStack.isNotEmpty ? AppColors.textPrimary : AppColors.textMuted,
                                onPressed: _undoStack.isNotEmpty ? _redo : null,
                                tooltip: 'Redo',
                              ),
                              TextButton.icon(
                                onPressed: _strokes.isNotEmpty ? _clearMask : null,
                                icon: Icon(Icons.clear_all, size: 16.sp, color: AppColors.accentError),
                                label: Text('Clear', style: TextStyle(color: AppColors.accentError, fontSize: 12.sp)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: AppColors.accentSuccess.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                        ),
                        child: Text('0 Credits • Free',
                            style: AppTextStyles.captionBold.copyWith(color: AppColors.accentSuccess)),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Bottom Primary Action
                  Obx(() {
                    final isProcessing = controller.isProcessing.value;
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isProcessing ? null : _executeErase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                        ),
                        icon: isProcessing
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Icon(Icons.auto_fix_high_rounded, size: 18.sp, color: Colors.white),
                        label: Text(
                          isProcessing ? controller.processingMessage.value : '⚡ ERASE OBJECT (Sub-Second)',
                          style: AppTextStyles.buttonMedium.copyWith(color: Colors.white),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_search_rounded, size: 48.sp, color: AppColors.textMuted),
          SizedBox(height: 12.h),
          Text('Select a photo to erase objects',
              style: AppTextStyles.bodyMediumBold.copyWith(color: AppColors.textPrimary)),
          SizedBox(height: 4.h),
          Text('Upload a high-res photo to remove people, text, or background clutter',
              style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          ElevatedButton.icon(
            onPressed: () => _pickImage(ImageSource.gallery),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
            ),
            icon: const Icon(Icons.photo_library_outlined, size: 16),
            label: const Text('Choose Photo'),
          ),
        ],
      ),
    );
  }
}

class _EraserCanvasPainter extends CustomPainter {
  final ui.Image image;
  final List<DrawnStroke> strokes;

  _EraserCanvasPainter({required this.image, required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();

    final double scale = min(size.width / imgW, size.height / imgH);
    final double offsetX = (size.width - (imgW * scale)) / 2;
    final double offsetY = (size.height - (imgH * scale)) / 2;

    final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
    final dstRect = Rect.fromLTWH(offsetX, offsetY, imgW * scale, imgH * scale);

    // 1. Draw source image fitted
    canvas.drawImageRect(image, srcRect, dstRect, Paint());

    // 2. Draw user strokes in semi-transparent neon violet
    final strokePaint = Paint()
      ..color = const Color(0x99A855F7) // Neon violet with opacity
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      strokePaint.strokeWidth = stroke.strokeWidth;
      canvas.drawPath(stroke.path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EraserCanvasPainter oldDelegate) => true;
}

