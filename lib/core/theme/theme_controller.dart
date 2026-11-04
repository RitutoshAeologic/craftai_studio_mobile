import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import 'app_theme.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find<ThemeController>();

  final Rx<AppThemePreset> currentPreset = AppThemePreset.luminousAurora.obs;

  @override
  void onInit() {
    super.onInit();
    currentPreset.value = AppColors.currentPreset;
  }

  void switchTheme(AppThemePreset preset) {
    if (currentPreset.value == preset) return;
    HapticFeedback.mediumImpact();
    // Apply static color tokens first so all Obx / reactive rebuilds immediately see updated colors
    AppColors.applyPreset(preset);
    currentPreset.value = preset;
    Get.changeTheme(AppTheme.getThemeForPreset(preset));
    update();
  }

  String getPresetName(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.luminousAurora:
        return 'Luminous Aurora';
      case AppThemePreset.warmCashmere:
        return 'Warm Cashmere';
      case AppThemePreset.coolPlatinum:
        return 'Cool Platinum Slate';
      case AppThemePreset.deepObsidian:
        return 'Deep Obsidian Dark';
    }
  }

  String getPresetDescription(AppThemePreset preset) {
    switch (preset) {
      case AppThemePreset.luminousAurora:
        return 'Porcelain Canvas • Frosted Glass • Ambient Glow';
      case AppThemePreset.warmCashmere:
        return 'Warm Ivory • Pearl Glass • Espresso Text';
      case AppThemePreset.coolPlatinum:
        return 'Silver-Mist • Ice White Panels • Charcoal Text';
      case AppThemePreset.deepObsidian:
        return 'Cosmic Obsidian • Dark Glass • Neon Accents';
    }
  }
}

