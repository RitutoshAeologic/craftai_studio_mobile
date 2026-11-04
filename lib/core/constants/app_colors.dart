import 'package:flutter/material.dart';

enum AppThemePreset {
  luminousAurora,
  warmCashmere,
  coolPlatinum,
  deepObsidian,
}

/// Centralized dynamic color palette and design tokens for CraftAI Studio.
/// Supports live switching between Luminous Aurora, Warm Cashmere, Cool Platinum, and Deep Obsidian.
class AppColors {
  AppColors._();

  static AppThemePreset currentPreset = AppThemePreset.luminousAurora;

  // ===========================================================================
  // DYNAMIC STUDIO CANVAS & SURFACES
  // ===========================================================================
  static Color get background => _background;
  static Color get backgroundElevated => _backgroundElevated;
  static Color get surface => _surface;
  static Color get surfaceLight => _surfaceLight;
  static Color get card => _card;
  static Color get border => _border;
  static Color get borderSubtle => _borderSubtle;

  // ===========================================================================
  // DYNAMIC GLASSMORPHIC TOKENS
  // ===========================================================================
  static Color get glassSurface => _glassSurface;
  static Color get glassSurfaceElevated => _glassSurfaceElevated;
  static Color get glassDarkSurface => _glassDarkSurface;
  static Color get glassBorder => _glassBorder;
  static Color get glassBorderSubtle => _glassBorderSubtle;

  // ===========================================================================
  // DYNAMIC TYPOGRAPHY TOKENS
  // ===========================================================================
  static Color get textPrimary => _textPrimary;
  static Color get textSecondary => _textSecondary;
  static Color get textMuted => _textMuted;
  static Color get textTertiary => _textTertiary;

  static bool get showAuroraOrbs => _showAuroraOrbs;

  // Private mutable backing fields (Default: Luminous Aurora)
  static Color _background = const Color(0xFFF8FAFC);
  static Color _backgroundElevated = const Color(0xFFFFFFFF);
  static Color _surface = const Color(0xFFFFFFFF);
  static Color _surfaceLight = const Color(0xFFF1F5F9);
  static Color _card = const Color(0xFFFFFFFF);
  static Color _border = const Color(0xFFE2E8F0);
  static Color _borderSubtle = const Color(0xFFEEF2F6);

  static Color _glassSurface = const Color(0xCCFFFFFF);
  static Color _glassSurfaceElevated = const Color(0xE6FFFFFF);
  static Color _glassDarkSurface = const Color(0xD9FFFFFF);
  static Color _glassBorder = const Color(0x336366F1);
  static Color _glassBorderSubtle = const Color(0x1F94A3B8);

  static Color _textPrimary = const Color(0xFF0F172A);
  static Color _textSecondary = const Color(0xFF475569);
  static Color _textMuted = const Color(0xFF64748B);
  static Color _textTertiary = const Color(0xFF94A3B8);
  static bool _showAuroraOrbs = true;

  // ===========================================================================
  // CONSTANT BRAND ACCENTS (Shared across themes)
  // ===========================================================================
  static const Color primary = Color(0xFF6366F1); // Cosmic Indigo
  static const Color secondary = Color(0xFF8B5CF6); // Cyber Violet
  static const Color vip = Color(0xFFA855F7);
  static const Color copilotPurple = Color(0xFF6366F1);
  static const Color copilotAccent = Color(0xFF8B5CF6);
  static const Color orangeAccent = Color(0xFFF59E0B);
  static const Color purpleAccent = Color(0xFF8B5CF6);
  static const Color cyanAccent = Color(0xFF06B6D4);
  static const Color emeraldAccent = Color(0xFF10B981);

  // ===========================================================================
  // SEMANTIC STATUS ACCENTS
  // ===========================================================================
  static const Color accentSuccess = Color(0xFF10B981); // Emerald
  static const Color accentWarning = Color(0xFFF59E0B); // Amber
  static const Color accentError = Color(0xFFEF4444); // Crimson

  // ===========================================================================
  // CORE NEUTRALS
  // ===========================================================================
  static const Color white = Colors.white;
  static const Color white70 = Colors.white70;
  static const Color white10 = Colors.white10;
  static const Color black = Colors.black;

  // ===========================================================================
  // AI GRADIENT RAMPS
  // ===========================================================================
  static const LinearGradient aiCosmicGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
      Color(0xFF06B6D4),
    ],
  );

  static const LinearGradient glassSpecularGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0x80FFFFFF),
      Color(0x1A6366F1),
    ],
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFAFFFFFF),
      Color(0xF0FFFFFF),
    ],
  );

  /// Apply a selected theme preset dynamically at runtime
  static void applyPreset(AppThemePreset preset) {
    currentPreset = preset;
    switch (preset) {
      case AppThemePreset.luminousAurora:
        _background = const Color(0xFFF8FAFC);
        _backgroundElevated = const Color(0xFFFFFFFF);
        _surface = const Color(0xFFFFFFFF);
        _surfaceLight = const Color(0xFFF1F5F9);
        _card = const Color(0xFFFFFFFF);
        _border = const Color(0xFFE2E8F0);
        _borderSubtle = const Color(0xFFEEF2F6);
        _glassSurface = const Color(0xCCFFFFFF);
        _glassSurfaceElevated = const Color(0xE6FFFFFF);
        _glassDarkSurface = const Color(0xD9FFFFFF);
        _glassBorder = const Color(0x336366F1);
        _glassBorderSubtle = const Color(0x1F94A3B8);
        _textPrimary = const Color(0xFF0F172A);
        _textSecondary = const Color(0xFF475569);
        _textMuted = const Color(0xFF64748B);
        _textTertiary = const Color(0xFF94A3B8);
        _showAuroraOrbs = true;
        break;
      case AppThemePreset.warmCashmere:
        _background = const Color(0xFFFAF9F6);
        _backgroundElevated = const Color(0xFFFFFDFB);
        _surface = const Color(0xFFFFFDFB);
        _surfaceLight = const Color(0xFFF5F3EF);
        _card = const Color(0xFFFFFDFB);
        _border = const Color(0xFFE7E5E4);
        _borderSubtle = const Color(0xFFF0EFEB);
        _glassSurface = const Color(0xD9FFFDFB);
        _glassSurfaceElevated = const Color(0xF2FFFDFB);
        _glassDarkSurface = const Color(0xEBFAF9F6);
        _glassBorder = const Color(0x266366F1);
        _glassBorderSubtle = const Color(0x24D6D3D1);
        _textPrimary = const Color(0xFF1C1917);
        _textSecondary = const Color(0xFF57534E);
        _textMuted = const Color(0xFF78716C);
        _textTertiary = const Color(0xFFA8A29E);
        _showAuroraOrbs = false;
        break;
      case AppThemePreset.coolPlatinum:
        _background = const Color(0xFFF1F5F9);
        _backgroundElevated = const Color(0xFFFFFFFF);
        _surface = const Color(0xFFFFFFFF);
        _surfaceLight = const Color(0xFFE2E8F0);
        _card = const Color(0xFFFFFFFF);
        _border = const Color(0xFFCBD5E1);
        _borderSubtle = const Color(0xFFE2E8F0);
        _glassSurface = const Color(0xD9FFFFFF);
        _glassSurfaceElevated = const Color(0xF2FFFFFF);
        _glassDarkSurface = const Color(0xEBF1F5F9);
        _glassBorder = const Color(0x336366F1);
        _glassBorderSubtle = const Color(0x2494A3B8);
        _textPrimary = const Color(0xFF090D16);
        _textSecondary = const Color(0xFF475569);
        _textMuted = const Color(0xFF64748B);
        _textTertiary = const Color(0xFF94A3B8);
        _showAuroraOrbs = false;
        break;
      case AppThemePreset.deepObsidian:
        _background = const Color(0xFF0B0D14);
        _backgroundElevated = const Color(0xFF121622);
        _surface = const Color(0xFF161B26);
        _surfaceLight = const Color(0xFF1F2636);
        _card = const Color(0xFF161B26);
        _border = const Color(0xFF283245);
        _borderSubtle = const Color(0xFF1C2230);
        _glassSurface = const Color(0x1AFFFFFF);
        _glassSurfaceElevated = const Color(0x26FFFFFF);
        _glassDarkSurface = const Color(0xB30B0D14);
        _glassBorder = const Color(0x2EFFFFFF);
        _glassBorderSubtle = const Color(0x14FFFFFF);
        _textPrimary = const Color(0xFFF8FAFC);
        _textSecondary = const Color(0xFF94A3B8);
        _textMuted = const Color(0xFF64748B);
        _textTertiary = const Color(0xFF475569);
        _showAuroraOrbs = true;
        break;
    }
  }
}
