import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import '../controllers/shell_controller.dart';
import '../../explore/views/explore_feed_view.dart';
import '../../studio/views/creation_studio_view.dart';
import '../../library/views/cloud_library_view.dart';
import '../../wallet/views/wallet_view.dart';

class HomeShellView extends StatelessWidget {
  const HomeShellView({super.key});

  @override
  Widget build(BuildContext context) {
    final ShellController controller = Get.put(ShellController());

    final List<Widget> screens = const [
      ExploreFeedView(),
      CreationStudioView(),
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
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Center(
                          child: Text('C', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18.sp)),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      RichText(
                        text: TextSpan(
                          text: 'CraftAI ',
                          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          children: const [
                            TextSpan(text: 'Studio', style: TextStyle(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Obx(() => GestureDetector(
                    onTap: () => controller.switchTab(3),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.primary, size: 14.sp),
                          SizedBox(width: 4.w),
                          Text(
                            '${controller.userCredits.value.toStringAsFixed(0)} Cr',
                            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  )),
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
      bottomNavigationBar: Obx(() => NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primary.withValues(alpha: 0.15),
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
      )),
    );
  }
}
