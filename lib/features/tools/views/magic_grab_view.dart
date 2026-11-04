import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/tool_result_preview_sheet.dart';
import 'magic_object_eraser_view.dart';

class MagicGrabView extends StatefulWidget {
  final String? initialImagePath;

  const MagicGrabView({super.key, this.initialImagePath});

  @override
  State<MagicGrabView> createState() => _MagicGrabViewState();
}

class _MagicGrabViewState extends State<MagicGrabView> {
  final ToolsController controller = Get.isRegistered<ToolsController>()
      ? Get.find<ToolsController>()
      : Get.put(ToolsController());

  String? _imagePath;
  ui.Image? _decodedImage;
  double _brushSize = 40.0;
  final List<DrawnStroke> _strokes = [];
  final List<DrawnStroke> _undoStack = [];
  Path? _currentPath;
  Offset? _currentCursorPosition;

  final GlobalKey _canvasKey = GlobalKey();
  final GlobalKey _repaintBoundaryKey = GlobalKey();

  // Grabbed repositioning state
  bool _isGrabbed = false;
  String? _cutoutUrl;
  String? _backgroundUrl;
  Offset _cutoutOffset = Offset.zero;
  double _cutoutScale = 1.0;
  double _baseScale = 1.0;
  Offset _panStart = Offset.zero;
  bool _showShadow = true;
  final double _shadowIntensity = 0.45;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.clearActiveSession();
      }
    });
    _imagePath = widget.initialImagePath;
    if (_imagePath != null && _imagePath!.isNotEmpty) {
      _loadImage(_imagePath!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<ToolsController>()) {
        controller.clearActiveSession();
      }
    });
    super.dispose();
  }

  Future<void> _loadImage(String path) async {
    try {
      Uint8List bytes;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        final client = HttpClient()
          ..badCertificateCallback = (cert, host, port) => true;
        final request = await client.getUrl(Uri.parse(path));
        request.headers.set('Bypass-Tunnel-Reminder', 'true');
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
          _isGrabbed = false;
          _cutoutUrl = null;
          _backgroundUrl = null;
          _cutoutOffset = Offset.zero;
          _cutoutScale = 1.0;
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
    setState(() {
      _undoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_undoStack.isEmpty) return;
    setState(() {
      _strokes.add(_undoStack.removeLast());
    });
  }

  void _clearStrokes() {
    setState(() {
      _strokes.clear();
      _undoStack.clear();
    });
  }

  Future<String?> _generateMaskBase64(Size viewportSize) async {
    if (_decodedImage == null || _strokes.isEmpty) return null;

    final origW = _decodedImage!.width.toDouble();
    final origH = _decodedImage!.height.toDouble();

    final double maxDim = max(origW, origH);
    final double normFactor = maxDim > 1280 ? (1280.0 / maxDim) : 1.0;
    final double targetW = (origW * normFactor).roundToDouble();
    final double targetH = (origH * normFactor).roundToDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, targetW, targetH));

    // Fill with solid black (#000000 = KEEP BACKGROUND)
    final bgPaint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(Rect.fromLTWH(0, 0, targetW, targetH), bgPaint);

    final double scale = min(viewportSize.width / origW, viewportSize.height / origH);
    final double offsetX = (viewportSize.width - (origW * scale)) / 2;
    final double offsetY = (viewportSize.height - (origH * scale)) / 2;

    // Paint strokes in solid white (#FFFFFF = GRAB SUBJECT)
    final maskPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final double effectiveScale = scale / normFactor;

    for (final stroke in _strokes) {
      maskPaint.strokeWidth = stroke.strokeWidth / effectiveScale;

      final matrix = Matrix4.identity()
        // ignore: deprecated_member_use
        ..scale(1 / effectiveScale, 1 / effectiveScale)
        // ignore: deprecated_member_use
        ..translate(-offsetX, -offsetY);

      final transformedPath = stroke.path.transform(matrix.storage);
      canvas.drawPath(transformedPath, maskPaint);
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(targetW.toInt(), targetH.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    return 'data:image/png;base64,${base64Encode(byteData.buffer.asUint8List())}';
  }

  Future<void> _executeGrab() async {
    if (_imagePath == null || _decodedImage == null) {
      Get.snackbar('Image Required', 'Please select a photo first.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    if (_strokes.isEmpty) {
      Get.snackbar('Select Object 🖐️', 'Brush over the subject you want to grab and reposition.',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
      return;
    }

    final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final maskBase64 = await _generateMaskBase64(renderBox.size);
    if (maskBase64 == null) return;

    HapticFeedback.heavyImpact();
    final result = await controller.runMagicGrab(
      path: _imagePath!,
      maskBase64: maskBase64,
    );

    if (result != null && result['cutout_url'] != null && mounted) {
      setState(() {
        _isGrabbed = true;
        _cutoutUrl = result['cutout_url'] as String;
        _backgroundUrl = result['background_url'] as String? ??
            result['clean_background_url'] as String? ??
            _imagePath;
        _cutoutOffset = Offset.zero;
        _cutoutScale = 1.0;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _saveAndExportComposed() async {
    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dataUri = 'data:image/png;base64,${base64Encode(bytes)}';

      if (Get.isRegistered<LibraryController>()) {
        LibraryController.to.addNewCreation(
          prompt: 'Magic Grab Repositioned Composition',
          credits: 0.0,
          previewUrl: dataUri,
          type: 'MAGIC_GRAB_COMPOSED',
          metadata: {
            'cutout_url': _cutoutUrl,
            'background_url': _backgroundUrl,
            'offset_x': _cutoutOffset.dx,
            'offset_y': _cutoutOffset.dy,
            'scale': _cutoutScale,
          },
        );
      }

      if (mounted) {
        ToolResultPreviewSheet.show(
          context: context,
          title: 'Magic Grab Composition',
          resultImageUrl: dataUri,
          originalImageUrl: _imagePath,
          creditsUsed: 0.0,
          badgeText: 'Live Repositioned Layer',
          enableBeforeAfter: true,
        );
      }
    } catch (e) {
      Get.snackbar('Export Failed', 'Could not export composed image: $e',
          snackPosition: SnackPosition.BOTTOM, backgroundColor: AppColors.surface, colorText: AppColors.accentWarning);
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _isGrabbed ? 'Reposition Object' : 'Magic Grab',
          style: AppTextStyles.h2.copyWith(fontSize: 18.sp),
        ),
        centerTitle: true,
        actions: [
          if (!_isGrabbed)
            IconButton(
              icon: Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
              onPressed: () => _pickImage(ImageSource.gallery),
            )
          else
            TextButton.icon(
              icon: Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
              label: Text('Reset', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
              onPressed: () {
                setState(() {
                  _cutoutOffset = Offset.zero;
                  _cutoutScale = 1.0;
                });
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Instruction Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              color: AppColors.surfaceLight,
              child: Row(
                children: [
                  Icon(
                    _isGrabbed ? Icons.touch_app_outlined : Icons.brush_outlined,
                    size: 16.sp,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      _isGrabbed
                          ? 'Drag with finger to move. Pinch to scale subject.'
                          : 'Brush over the object you want to grab and move freely.',
                      style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            // Canvas Workspace
            Expanded(
              child: Center(
                child: _imagePath == null
                    ? _buildEmptyState()
                    : _isGrabbed
                        ? _buildInteractiveCanvas()
                        : _buildBrushCanvas(),
              ),
            ),

            // Controls Toolbar
            if (_imagePath != null)
              _isGrabbed ? _buildRepositionToolbar() : _buildBrushToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 80.w,
          height: 80.w,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text('🖐️', style: TextStyle(fontSize: 36.sp)),
          ),
        ),
        SizedBox(height: 16.h),
        Text('Select Photo to Grab Object', style: AppTextStyles.bodyMediumBold.copyWith(fontSize: 16.sp)),
        SizedBox(height: 6.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Text(
            'Lifts any person or item into an interactive layer, seamlessly inpainting the background like Canva & Google Pixel.',
            textAlign: TextAlign.center,
            style: AppTextStyles.captionXs.copyWith(color: AppColors.textSecondary),
          ),
        ),
        SizedBox(height: 20.h),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusRound)),
          ),
          icon: const Icon(Icons.photo_library, size: 18),
          label: const Text('Choose Photo'),
          onPressed: () => _pickImage(ImageSource.gallery),
        ),
      ],
    );
  }

  Widget _buildBrushCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localPos = box.globalToLocal(details.globalPosition);
            final newPath = Path()..moveTo(localPos.dx, localPos.dy);
            setState(() {
              _currentPath = newPath;
              _currentCursorPosition = localPos;
              _strokes.add(DrawnStroke(path: newPath, strokeWidth: _brushSize));
              _undoStack.clear();
            });
          },
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final localPos = box.globalToLocal(details.globalPosition);
            setState(() {
              _currentCursorPosition = localPos;
              _currentPath?.lineTo(localPos.dx, localPos.dy);
            });
          },
          onPanEnd: (_) {
            setState(() {
              _currentPath = null;
              _currentCursorPosition = null;
            });
          },
          child: RepaintBoundary(
            key: _canvasKey,
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _BrushMaskPainter(
                image: _decodedImage,
                strokes: _strokes,
                cursorPosition: _currentCursorPosition,
                brushSize: _brushSize,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInteractiveCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              // 1. Infilled Background Plate
              if (_backgroundUrl != null)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: _backgroundUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    ),
                  ),
                ),

              // 2. Dynamic Ground Drop Shadow (shift along with subject)
              if (_showShadow && _cutoutUrl != null)
                Transform.translate(
                  offset: Offset(_cutoutOffset.dx + 4, _cutoutOffset.dy + 24),
                  child: Transform.scale(
                    scale: _cutoutScale,
                    child: Center(
                      child: Container(
                        width: 140.w,
                        height: 24.h,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.elliptical(140.w, 24.h)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _shadowIntensity),
                              blurRadius: 28,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // 3. Moveable & Scalable Cutout Layer
              if (_cutoutUrl != null)
                GestureDetector(
                  onScaleStart: (details) {
                    _baseScale = _cutoutScale;
                    _panStart = details.focalPoint - _cutoutOffset;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _cutoutScale = (_baseScale * details.scale).clamp(0.4, 3.0);
                      _cutoutOffset = details.focalPoint - _panStart;
                    });
                  },
                  child: Transform.translate(
                    offset: _cutoutOffset,
                    child: Transform.scale(
                      scale: _cutoutScale,
                      child: Center(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(AppDimens.radiusSm),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: _cutoutUrl!,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBrushToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Brush size slider and undo/redo row
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.undo,
                    color: _strokes.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary),
                onPressed: _strokes.isNotEmpty ? _undo : null,
              ),
              IconButton(
                icon: Icon(Icons.redo,
                    color: _undoStack.isNotEmpty ? AppColors.textPrimary : AppColors.textTertiary),
                onPressed: _undoStack.isNotEmpty ? _redo : null,
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: _strokes.isNotEmpty ? AppColors.accentError : AppColors.textTertiary),
                onPressed: _strokes.isNotEmpty ? _clearStrokes : null,
              ),
              SizedBox(width: 8.w),
              Icon(Icons.brush, size: 16.sp, color: AppColors.textSecondary),
              Expanded(
                child: Slider(
                  value: _brushSize,
                  min: 10.0,
                  max: 90.0,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _brushSize = val),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Primary Grab Action
          Obx(() {
            final isProcessing = controller.isProcessing.value;
            return SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                  elevation: 0,
                ),
                icon: isProcessing
                    ? SizedBox(
                        width: 18.w,
                        height: 18.w,
                        child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high, size: 18, color: Colors.white),
                label: Text(
                  isProcessing
                      ? (controller.processingMessage.value.isNotEmpty
                          ? controller.processingMessage.value
                          : 'Extracting layer...')
                      : 'Grab Subject 🖐️',
                  style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 14.sp),
                ),
                onPressed: isProcessing ? null : _executeGrab,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRepositionToolbar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shadow controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.wb_twilight, size: 16.sp, color: AppColors.textSecondary),
                  SizedBox(width: 6.w),
                  Text('Ground Shadow', style: AppTextStyles.captionBold.copyWith(color: AppColors.textPrimary)),
                ],
              ),
              Switch.adaptive(
                value: _showShadow,
                activeTrackColor: AppColors.primary,
                onChanged: (val) => setState(() => _showShadow = val),
              ),
            ],
          ),
          SizedBox(height: 10.h),

          // Action Buttons: Re-brush & Save
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.border),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                  ),
                  icon: Icon(Icons.brush, size: 16, color: AppColors.textSecondary),
                  label: Text('Re-brush', style: AppTextStyles.captionBold.copyWith(color: AppColors.textSecondary)),
                  onPressed: () {
                    setState(() {
                      _isGrabbed = false;
                      _strokes.clear();
                    });
                  },
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentSuccess,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.check, size: 18, color: Colors.white),
                  label: Text(
                    'Save Composition',
                    style: AppTextStyles.button.copyWith(color: Colors.white, fontSize: 14.sp),
                  ),
                  onPressed: _saveAndExportComposed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrushMaskPainter extends CustomPainter {
  final ui.Image? image;
  final List<DrawnStroke> strokes;
  final Offset? cursorPosition;
  final double brushSize;

  _BrushMaskPainter({
    required this.image,
    required this.strokes,
    required this.cursorPosition,
    required this.brushSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      final imgW = image!.width.toDouble();
      final imgH = image!.height.toDouble();
      final scale = min(size.width / imgW, size.height / imgH);
      final destW = imgW * scale;
      final destH = imgH * scale;
      final destX = (size.width - destW) / 2;
      final destY = (size.height - destH) / 2;

      final srcRect = Rect.fromLTWH(0, 0, imgW, imgH);
      final destRect = Rect.fromLTWH(destX, destY, destW, destH);
      canvas.drawImageRect(image!, srcRect, destRect, Paint());
    }

    // Draw strokes in semi-transparent purple highlight
    final strokePaint = Paint()
      ..color = const Color(0x99A855F7)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      strokePaint.strokeWidth = stroke.strokeWidth;
      canvas.drawPath(stroke.path, strokePaint);
    }

    // Draw cursor circle if brushing
    if (cursorPosition != null) {
      final cursorPaint = Paint()
        ..color = const Color(0xFFA855F7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(cursorPosition!, brushSize / 2, cursorPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BrushMaskPainter oldDelegate) => true;
}
