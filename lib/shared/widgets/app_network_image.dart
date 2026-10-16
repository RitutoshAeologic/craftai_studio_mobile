import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimens.dart';

/// [AppNetworkImage] is a shared, cached image component.
/// Mandated by rules.md §5 to ensure consistent placeholder loading
/// and error-handling without duplicating CachedNetworkImage boilerplate.
/// Handles remote URLs, base64 data URIs, and local device file paths.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  /// Remote image URL, local file path, or data URI to load.
  final String imageUrl;

  /// Width of the image container.
  final double? width;

  /// Height of the image container.
  final double? height;

  /// BoxFit strategy (defaults to [BoxFit.cover]).
  final BoxFit fit;

  /// Border radius applied to the image corners.
  final BorderRadius? borderRadius;

  /// Custom placeholder widget override.
  final Widget? placeholder;

  /// Custom error widget override.
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppDimens.radiusMd);

    Widget buildError() =>
        errorWidget ??
        Container(
          color: AppColors.surfaceLight,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textMuted,
              size: 24,
            ),
          ),
        );

    Widget buildPlaceholder() =>
        placeholder ??
        Container(
          color: AppColors.surfaceLight,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ),
        );

    Widget imageWidget;
    if (imageUrl.trim().isEmpty) {
      imageWidget = buildError();
    } else if (imageUrl.startsWith('data:image/') && imageUrl.contains(',')) {
      try {
        final base64String = imageUrl.split(',').last;
        final bytes = base64Decode(base64String);
        imageWidget = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, __, ___) => buildError(),
        );
      } catch (_) {
        imageWidget = buildError();
      }
    } else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => buildPlaceholder(),
        errorWidget: (_, __, ___) => buildError(),
      );
    } else {
      String cleanPath = imageUrl;
      if (cleanPath.startsWith('file://')) {
        cleanPath = cleanPath.replaceFirst('file://', '');
      }
      imageWidget = Image.file(
        File(cleanPath),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => buildError(),
      );
    }

    if (borderRadius != null || effectiveRadius != BorderRadius.zero) {
      imageWidget = ClipRRect(
        borderRadius: effectiveRadius,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
