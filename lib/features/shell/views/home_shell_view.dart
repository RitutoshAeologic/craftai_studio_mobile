import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
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
                  Row(
                    children: [
                      CreditCostChip(
                        creditsRx: controller.userCredits,
                        onTap: () => controller.switchTab(4),
                        isHighlighted: true,
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: () => _showAccountSheet(context),
                        child: Container(
                          width: 32.w,
                          height: 32.w,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Icon(
                            Icons.person_outline,
                            size: 18.sp,
                            color: AppColors.textPrimary,
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

  void _showAccountSheet(BuildContext context) {
    final email = Supabase.instance.client.auth.currentUser?.email ?? 'Creator Account';
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          border: Border.all(color: AppColors.border),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'Account & Session',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                email,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Divider(color: AppColors.border, height: 1.h),
              SizedBox(height: 12.h),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentError.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: const Icon(Icons.logout_rounded, color: AppColors.accentError),
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(
                    color: AppColors.accentError,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  'End your current session on this device',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.sp,
                  ),
                ),
                onTap: () {
                  Get.back();
                  _confirmSignOut();
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _confirmSignOut() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'Sign Out?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out of CraftAI Studio?',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentError,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            onPressed: () {
              Get.back();
              if (Get.isRegistered<AuthController>()) {
                Get.find<AuthController>().signOut();
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
