import 'package:flutter/material.dart';

/// Normalized (0.0–1.0) element descriptor matching the backend Pillow/CairoSVG
/// JSONB template schema for Phase 3 Marketing Poster live canvas preview.
class PosterElementLayout {
  final String id;
  final String type; // 'background' | 'image' | 'headline' | 'subtext' | 'badge' | 'shape'
  final double x; // 0.0 - 1.0
  final double y; // 0.0 - 1.0
  final double width; // 0.0 - 1.0
  final double height; // 0.0 - 1.0
  final String? text;
  final double fontSizeNorm; // Relative to canvas height (0.0 - 1.0)
  final Color color;
  final Color? backgroundColor;
  final TextAlign textAlign;
  final double borderRadiusNorm;

  const PosterElementLayout({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.text,
    this.fontSizeNorm = 0.05,
    this.color = Colors.white,
    this.backgroundColor,
    this.textAlign = TextAlign.left,
    this.borderRadiusNorm = 0.02,
  });

  factory PosterElementLayout.fromJson(Map<String, dynamic> json) {
    return PosterElementLayout(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? 'shape').toString(),
      x: ((json['x'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      y: ((json['y'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      width: ((json['width'] as num?)?.toDouble() ?? 1.0).clamp(0.0, 1.0),
      height: ((json['height'] as num?)?.toDouble() ?? 0.1).clamp(0.0, 1.0),
      text: json['text'] as String?,
      fontSizeNorm: ((json['font_size_norm'] as num?)?.toDouble() ?? 0.05).clamp(0.01, 0.25),
      color: _parseHexColor(json['color'] as String?, defaultColor: Colors.white),
      backgroundColor: json['background_color'] != null
          ? _parseHexColor(json['background_color'] as String?, defaultColor: Colors.transparent)
          : null,
      textAlign: _parseAlign(json['align'] as String?),
      borderRadiusNorm: ((json['border_radius_norm'] as num?)?.toDouble() ?? 0.02).clamp(0.0, 0.5),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        if (text != null) 'text': text,
        'font_size_norm': fontSizeNorm,
        'color': _toHex(color),
        if (backgroundColor != null) 'background_color': _toHex(backgroundColor!),
        'align': textAlign.name,
        'border_radius_norm': borderRadiusNorm,
      };

  static Color _parseHexColor(String? hex, {required Color defaultColor}) {
    if (hex == null || hex.trim().isEmpty) return defaultColor;
    final cleaned = hex.trim().replaceFirst('#', '');
    final withAlpha = cleaned.length == 6 ? 'FF$cleaned' : cleaned;
    final val = int.tryParse(withAlpha, radix: 16);
    return val != null ? Color(val) : defaultColor;
  }

  static String _toHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  static TextAlign _parseAlign(String? align) {
    return switch (align?.toLowerCase()) {
      'center' => TextAlign.center,
      'right' => TextAlign.right,
      _ => TextAlign.left,
    };
  }
}

/// Remote or preset normalized `0.0–1.0` JSONB layout template for Marketing Posters.
class PosterLayoutTemplate {
  final String templateId;
  final String category;
  final Color backgroundStart;
  final Color backgroundEnd;
  final List<PosterElementLayout> elements;

  const PosterLayoutTemplate({
    required this.templateId,
    required this.category,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.elements,
  });

  factory PosterLayoutTemplate.fromJson(Map<String, dynamic> json) {
    final rawElements = json['elements'] as List? ?? const [];
    return PosterLayoutTemplate(
      templateId: (json['template_id'] ?? 'remote_custom').toString(),
      category: (json['category'] ?? 'Commercial').toString(),
      backgroundStart: PosterElementLayout._parseHexColor(
        json['background_start'] as String?,
        defaultColor: const Color(0xFF141824),
      ),
      backgroundEnd: PosterElementLayout._parseHexColor(
        json['background_end'] as String?,
        defaultColor: const Color(0xFF283048),
      ),
      elements: rawElements
          .whereType<Map>()
          .map((e) => PosterElementLayout.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'template_id': templateId,
        'category': category,
        'background_start': PosterElementLayout._toHex(backgroundStart),
        'background_end': PosterElementLayout._toHex(backgroundEnd),
        'elements': elements.map((e) => e.toJson()).toList(),
      };

  /// Returns a normalized 0.0–1.0 layout tuned for the selected poster category.
  static PosterLayoutTemplate forCategory(String category) {
    final (start, end, accent) = switch (category) {
      'Beverage' => (const Color(0xFF1A120B), const Color(0xFF3C2A21), const Color(0xFFF59E0B)),
      'Fashion' => (const Color(0xFF18181B), const Color(0xFF3F3F46), const Color(0xFFEC4899)),
      'Hiring' => (const Color(0xFF0F172A), const Color(0xFF1E3A8A), const Color(0xFF38BDF8)),
      'Flash Sale' => (const Color(0xFF2A0909), const Color(0xFF7F1D1D), const Color(0xFFFACC15)),
      'Event' => (const Color(0xFF1E1B4B), const Color(0xFF4C1D95), const Color(0xFFA78BFA)),
      _ => (const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF10B981)),
    };

    return PosterLayoutTemplate(
      templateId: 'preset_${category.toLowerCase().replaceAll(' ', '_')}',
      category: category,
      backgroundStart: start,
      backgroundEnd: end,
      elements: [
        PosterElementLayout(
          id: 'hero_image',
          type: 'image',
          x: 0.08,
          y: 0.24,
          width: 0.84,
          height: 0.48,
          backgroundColor: Colors.white.withValues(alpha: 0.08),
          borderRadiusNorm: 0.04,
        ),
        PosterElementLayout(
          id: 'discount_badge',
          type: 'badge',
          x: 0.64,
          y: 0.06,
          width: 0.28,
          height: 0.08,
          color: Colors.black,
          backgroundColor: accent,
          fontSizeNorm: 0.036,
          textAlign: TextAlign.center,
          borderRadiusNorm: 0.04,
        ),
        const PosterElementLayout(
          id: 'headline',
          type: 'headline',
          x: 0.08,
          y: 0.06,
          width: 0.54,
          height: 0.14,
          color: Colors.white,
          fontSizeNorm: 0.062,
          textAlign: TextAlign.left,
        ),
        PosterElementLayout(
          id: 'subtext',
          type: 'subtext',
          x: 0.08,
          y: 0.76,
          width: 0.84,
          height: 0.16,
          color: Colors.white.withValues(alpha: 0.85),
          fontSizeNorm: 0.036,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
