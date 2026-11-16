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
import '../widgets/expandable_navigation_fab.dart';
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
import '../../../shared/widgets/interactions/bouncy_tap.dart';

class HomeShellView extends StatefulWidget {
  const HomeShellView({super.key});

  @override
  State<HomeShellView> createState() => _HomeShellViewState();
}

class _HomeShellViewState extends State<HomeShellView> {
  late GlobalKey<ExpandableNavigationFabState> _fabKey;

  @override
  void initState() {
    super.initState();
    _fabKey = GlobalKey<ExpandableNavigationFabState>();
  }

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

        // 0. Collapse Expandable FAB if open
        if (_fabKey.currentState?.isExpanded == true) {
          _fabKey.currentState?.collapse();
          return;
        }

        // 1. Back Navigation During Image Generation Check
        if (Get.isRegistered<StudioController>()) {
          final studioController = Get.find<StudioController>();
          if (studioController.isGenerating.value) {
            _showGenerationWarningDialog(context);
            return;
          }
        }

        // 2. Non-Explore tabs (Studio, AI Tools, Library) navigate to Explore (Tab 0)
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

        final topPadding = MediaQuery.paddingOf(context).top;
        final bottomPadding = MediaQuery.paddingOf(context).bottom;

        return Scaffold(
          key: ValueKey('shell_$activePreset'),
          extendBody: true,
          backgroundColor: AppColors.background,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56.h + topPadding),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 56.h + topPadding,
                  padding: EdgeInsets.only(
                    top: topPadding,
                    left: 16.w,
                    right: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background.withValues(alpha: 0.88),
                    border: Border(
                      bottom: BorderSide(
                        color: AppColors.borderSubtle,
                        width: 0.8.w,
                      ),
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.center,
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CreditCostChip(
                              creditsRx: controller.userCredits,
                              onTap: () => Get.to(() => const WalletView()),
                              isHighlighted: true,
                            ),
                            SizedBox(width: 8.w),
                            Tooltip(
                              message: 'Profile',
                              child: BouncyTap(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  Get.to(() => const ProfileView());
                                },
                                child: Container(
                                  width: 32.w,
                                  height: 32.w,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AppColors.aiCosmicGradient,
                                    border: Border.all(
                                      color: AppColors.glassBorderSubtle,
                                      width: 1.2.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8.r,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person_rounded,
                                      size: 17.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
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
          body: Stack(
            fit: StackFit.expand,
            children: [
              LuminousMeshCanvas(
                showOrbs: AppColors.showAuroraOrbs,
                child: IndexedStack(
                  key: ValueKey('stack_$activePreset'),
                  index: controller.currentIndex.value,
                  children: screens,
                ),
              ),
              ExpandableNavigationFab(
                key: _fabKey,
                bottomOffset:
                    (bottomPadding > 0 ? bottomPadding + 8.h : 14.h) +
                        58.h +
                        12.h,
                rightOffset: 16.w,
                items: [
                  FabMenuItem(
                    title: 'Prompt to Image',
                    subtitle: 'Generate AI art with prompts & styles',
                    icon: Icons.auto_awesome_rounded,
                    accentColor: AppColors.primary,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.switchTab(1);
                    },
                  ),
                  FabMenuItem(
                    title: 'AI Tools',
                    subtitle: 'All specialized editing & enhancement tools',
                    icon: Icons.auto_fix_high_rounded,
                    accentColor: const Color(0xFFA855F7),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      controller.switchTab(2);
                    },
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: EdgeInsets.only(
                bottom: bottomPadding > 0 ? bottomPadding + 8.h : 14.h,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28.r),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 58.h,
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 5.h),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: AppColors.glassBorder,
                        width: 1.2.w,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16.r,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Obx(() {
                      final currentIndex = controller.currentIndex.value;
                      final isExploreSelected = currentIndex == 0;
                      final isLibrarySelected = currentIndex == 3;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNavItem(
                            isSelected: isExploreSelected,
                            selectedIcon: Icons.explore,
                            unselectedIcon: Icons.explore_outlined,
                            label: AppStrings.tabExplore,
                            onTap: () => controller.switchTab(0),
                          ),
                          SizedBox(width: 6.w),
                          _buildNavItem(
                            isSelected: isLibrarySelected,
                            selectedIcon: Icons.folder,
                            unselectedIcon: Icons.folder_outlined,
                            label: AppStrings.tabLibrary,
                            onTap: () => controller.switchTab(3),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNavItem({
    required bool isSelected,
    required IconData selectedIcon,
    required IconData unselectedIcon,
    required String label,
    required VoidCallback onTap,
  }) {
    return BouncyTap(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeInOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12.w : 8.w,
          vertical: 6.h,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.88)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22.r),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 10.r,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 20.sp,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              child: !isSelected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 5.w),
                        Text(
                          label,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
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
