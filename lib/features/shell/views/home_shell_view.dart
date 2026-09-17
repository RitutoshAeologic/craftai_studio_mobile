import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import '../controllers/shell_controller.dart';
import '../../explore/views/explore_feed_view.dart';
import '../../studio/presentation/views/creation_studio_view.dart';
import '../../tools/views/ai_tools_view.dart';
import '../../library/views/cloud_library_view.dart';
import '../../wallet/views/wallet_view.dart';
import '../../../shared/widgets/credit_cost_chip.dart';

class HomeShellView extends StatelessWidget {
  const HomeShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final ShellController controller = Get.put(ShellController());

    final List<Widget> screens = const [
      ExploreFeedView(),
      CreationStudioView(),
      AiToolsView(),
      CloudLibraryView(),
      WalletView(),
    ];

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60.h),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 1.w)),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32.w,
                        height: 32.w,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text('C', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      RichText(
                        text: TextSpan(
                          text: 'CraftAI ',
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          children: const [
                            TextSpan(text: 'Studio', style: TextStyle(color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  CreditCostChip(
                    creditsRx: controller.userCredits,
                    onTap: () => controller.switchTab(4),
                    isHighlighted: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Obx(() => IndexedStack(
        index: controller.currentIndex.value,
        children: screens,
      )),
      bottomNavigationBar: Obx(() => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.w)),
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            height: 64.h,
            indicatorColor: AppColors.border.withValues(alpha: 0.5),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return TextStyle(color: AppColors.primary, fontSize: 11.sp, fontWeight: FontWeight.bold);
              }
              return TextStyle(color: AppColors.textSecondary, fontSize: 11.sp);
            }),
          ),
          child: NavigationBar(
            selectedIndex: controller.currentIndex.value,
            onDestinationSelected: controller.switchTab,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.explore, color: AppColors.primary),
              label: AppStrings.tabExplore,
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_awesome_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.auto_awesome, color: AppColors.primary),
              label: AppStrings.tabStudio,
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_fix_high_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.auto_fix_high, color: AppColors.primary),
              label: 'AI Tools',
            ),
            NavigationDestination(
              icon: Icon(Icons.folder_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.folder, color: AppColors.primary),
              label: AppStrings.tabLibrary,
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.textSecondary),
              selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.primary),
              label: AppStrings.tabWallet,
            ),
          ],
        ),
      ))),
    );
  }
}
