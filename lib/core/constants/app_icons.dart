import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Centralized modern iconography tokens for CraftAI Studio.
/// Replaces raw unicode emojis and stock Material icons with unified,
/// precision-drawn Apple SF Symbols / Cupertino / Modern vector icons.
class AppIcons {
  AppIcons._();

  // ===========================================================================
  // CREATIVE TOOL VECTOR ICONS (Replaces raw system emojis)
  // ===========================================================================
  /// Background Remover (Replaces ✂️)
  static const IconData bgRemover = CupertinoIcons.scissors;

  /// Magic Object Eraser (Replaces 🪄)
  static const IconData magicEraser = CupertinoIcons.wand_stars;

  /// Photo Colorizer (Replaces 🎨)
  static const IconData photoColorizer = CupertinoIcons.paintbrush;

  /// AI Backgrounds (Replaces 🖼️)
  static const IconData aiBackgrounds = CupertinoIcons.photo_fill_on_rectangle_fill;

  /// AI Expand (Replaces 📐)
  static const IconData aiExpand = CupertinoIcons.fullscreen;

  /// 4K Upscaler (Replaces 🔍)
  static const IconData upscaler = CupertinoIcons.arrow_up_right_circle_fill;

  /// Magic Grab (Phase 1 preview)
  static const IconData magicGrab = CupertinoIcons.hand_draw;

  /// E-Commerce Product Pack
  static const IconData productPack = CupertinoIcons.cube_box;

  /// Marketing Poster
  static const IconData marketingPoster = CupertinoIcons.speaker_2;

  // ===========================================================================
  // BACKDROP PRESET ICONS (Replaces emojis in AI Backgrounds sheet)
  // ===========================================================================
  static const IconData backdropPureWhite = CupertinoIcons.circle;
  static const IconData backdropSmart = CupertinoIcons.lightbulb;
  static const IconData backdropMarble = CupertinoIcons.sparkles;
  static const IconData backdropWood = CupertinoIcons.circle_grid_hex;
  static const IconData backdropNeon = CupertinoIcons.bolt_fill;
  static const IconData backdropCustom = CupertinoIcons.pencil_outline;

  // ===========================================================================
  // NAVIGATION BAR ICONS
  // ===========================================================================
  static const IconData navExplore = CupertinoIcons.compass;
  static const IconData navExploreSelected = CupertinoIcons.compass_fill;

  static const IconData navStudio = CupertinoIcons.sparkles;
  static const IconData navStudioSelected = CupertinoIcons.sparkles;

  static const IconData navTools = CupertinoIcons.wand_stars;
  static const IconData navToolsSelected = CupertinoIcons.wand_stars;

  static const IconData navLibrary = CupertinoIcons.folder;
  static const IconData navLibrarySelected = CupertinoIcons.folder_fill;

  static const IconData navProfile = Icons.person_outline;
  static const IconData navProfileSelected = Icons.person;

  // ===========================================================================
  // ACTION & STATUS ICONS
  // ===========================================================================
  static const IconData credits = CupertinoIcons.bolt_fill;
  static const IconData search = CupertinoIcons.search;
  static const IconData filter = CupertinoIcons.slider_horizontal_3;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData upload = CupertinoIcons.cloud_upload;
  static const IconData download = CupertinoIcons.arrow_down_to_line;
  static const IconData share = CupertinoIcons.share;
  static const IconData aspectCrop = CupertinoIcons.crop;
  static const IconData check = CupertinoIcons.checkmark_alt;
  static const IconData alert = CupertinoIcons.exclamationmark_triangle;
  static const IconData info = CupertinoIcons.info;
}
