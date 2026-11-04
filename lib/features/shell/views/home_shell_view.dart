import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import '../controllers/shell_controller.dart';
import '../../explore/views/explore_feed_view.dart';
import '../../explore/controllers/explore_controller.dart';
import '../../studio/presentation/views/creation_studio_view.dart';
import '../../studio/presentation/controllers/studio_controller.dart';
import '../../tools/views/ai_tools_view.dart';
import '../../library/views/cloud_library_view.dart';
import '../../profile/views/profile_view.dart';
import '../../wallet/views/wallet_view.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../shared/widgets/credit_cost_chip.dart';
import '../../../shared/widgets/glass/luminous_mesh_canvas.dart';

class HomeShellView extends StatelessWidget {
  const HomeShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final ShellController controller = Get.put(ShellController());
    final ThemeController themeController = Get.isRegistered<ThemeController>()
        ? Get.find<ThemeController>()
        : Get.put(ThemeController());

    if (!Get.isRegistered<ExploreController>()) {
      Get.put(ExploreController());
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;

        // 1. Back Navigation During Image Generation Check
        if (Get.isRegistered<StudioController>()) {
          final studioController = Get.find<StudioController>();
          if (studioController.isGenerating.value) {
            _showGenerationWarningDialog(context);
            return;
          }
        }

        // 2. Non-Explore tabs (Studio, AI Tools, Library, Profile) navigate to Explore (Tab 0)
        if (controller.currentIndex.value != 0) {
          controller.switchTab(0);
          return;
        }

        // 3. Explore screen: Pressing back exits the application
        SystemNavigator.pop();
      },
      child: Obx(() {
        final activePreset = themeController.currentPreset.value;

        final List<Widget> screens = [
          KeyedSubtree(
              key: ValueKey('explore_${activePreset.name}'),
              child: const ExploreFeedView()),
          KeyedSubtree(
              key: ValueKey('studio_${activePreset.name}'),
              child: const CreationStudioView()),
          KeyedSubtree(
              key: ValueKey('tools_${activePreset.name}'),
              child: const AiToolsView()),
          KeyedSubtree(
              key: ValueKey('library_${activePreset.name}'),
              child: const CloudLibraryView()),
          KeyedSubtree(
              key: ValueKey('profile_${activePreset.name}'),
              child: const ProfileView()),
        ];

        return Scaffold(
          key: ValueKey('shell_$activePreset'),
          extendBody: true,
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60.h),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.glassDarkSurface,
                    border: Border(
                      bottom: BorderSide(
                          color: AppColors.glassBorderSubtle, width: 1.w),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 34.w,
                                  height: 34.w,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.aiCosmicGradient,
                                    borderRadius: BorderRadius.circular(10.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10.r,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      'C',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18.sp,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Flexible(
                                  child: RichText(
                                    overflow: TextOverflow.ellipsis,
                                    text: TextSpan(
                                      text: 'CraftAI ',
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.3,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Studio',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              CreditCostChip(
                                creditsRx: controller.userCredits,
                                onTap: () => Get.to(() => const WalletView()),
                                isHighlighted: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: LuminousMeshCanvas(
            showOrbs: AppColors.showAuroraOrbs,
            child: IndexedStack(
              key: ValueKey('stack_$activePreset'),
              index: controller.currentIndex.value,
              children: screens,
            ),
          ),
          bottomNavigationBar: Container(
            margin: EdgeInsets.only(
              left: 18.w,
              right: 18.w,
              bottom: MediaQuery.paddingOf(context).bottom > 0
                  ? MediaQuery.paddingOf(context).bottom + 6.h
                  : 18.h,
            ),
            // No decoration/boxShadow here: it was what made the bar look grey/solid
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    // lower alpha = more transparent (try 0.08 – 0.25)
                    color: AppColors.glassSurface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(28.r),
                    border: Border.all(
                      color: AppColors.glassBorder,
                      width: 1.2.w,
                    ),
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      height: 62.h,
                      indicatorColor: AppColors.primary.withValues(alpha: 0.14),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return TextStyle(
                            color: AppColors.primary,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          );
                        }
                        return TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w500,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      selectedIndex: controller.currentIndex.value,
                      onDestinationSelected: controller.switchTab,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700,fontSize: 12)),
                      destinations: [
                        NavigationDestination(
                          icon: Icon(Icons.explore_outlined,
                              color: AppColors.textSecondary),
                          selectedIcon:
                              Icon(Icons.explore, color: AppColors.primary),
                          label: AppStrings.tabExplore,
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.auto_awesome_outlined,
                              color: AppColors.textSecondary),
                          selectedIcon: Icon(Icons.auto_awesome,
                              color: AppColors.primary),
                          label: AppStrings.tabStudio,
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.auto_fix_high_outlined,
                              color: AppColors.textSecondary),
                          selectedIcon: Icon(Icons.auto_fix_high,
                              color: AppColors.primary),
                          label: 'AI Tools',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.folder_outlined,
                              color: AppColors.textSecondary),
                          selectedIcon:
                              Icon(Icons.folder, color: AppColors.primary),
                          label: AppStrings.tabLibrary,
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline,
                              color: AppColors.textSecondary),
                          selectedIcon:
                              Icon(Icons.person, color: AppColors.primary),
                          label: AppStrings.tabProfile,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  void _showGenerationWarningDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        ),
        backgroundColor: AppColors.surface,
        child: Padding(
          padding: EdgeInsets.all(AppDimens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.accentWarning.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top_rounded,
                  color: AppColors.accentWarning,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: AppDimens.vSpacingMd),
              Text(
                'Generation in Progress',
                style: AppTextStyles.h3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'An image is currently being generated. You cannot navigate back while image generation is in progress. Please wait for it to complete.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppDimens.vSpacingLg),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                    ),
                  ),
                  child: Text('Understood', style: AppTextStyles.buttonSmall),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
