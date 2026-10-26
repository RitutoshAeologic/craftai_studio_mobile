import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final WalletController controller = Get.put(WalletController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: Navigator.canPop(context)
          ? AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
                onPressed: () => Get.back(),
              ),
              title: Text(
                'Wallet & Credits',
                style: AppTextStyles.h2,
              ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(1.h),
                child: Container(color: AppColors.border, height: 1.h),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dual Balance Card
            Obx(() => Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.surface, AppColors.card],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Purchased Balance', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                          SizedBox(height: 2.h),
                          Text('${controller.wallet.value.purchasedBalance.toStringAsFixed(0)} Cr', style: TextStyle(color: AppColors.primary, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Earned Royalties', style: TextStyle(color: AppColors.textMuted, fontSize: 11.sp)),
                          SizedBox(height: 2.h),
                          Text('${controller.wallet.value.earnedRoyaltyBalance.toStringAsFixed(1)} Cr', style: TextStyle(color: AppColors.accentSuccess, fontSize: 22.sp, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Divider(color: AppColors.border, height: 1.h),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Cash Value: \$${(controller.wallet.value.earnedRoyaltyBalance * 0.1).toStringAsFixed(2)} USD', style: TextStyle(color: AppColors.textSecondary, fontSize: 12.sp)),
                      ElevatedButton(
                        onPressed: controller.requestPayout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentSuccess,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6.r)),
                        ),
                        child: Text('Withdraw Payout', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            )),

            SizedBox(height: 20.h),
            Text('Buy Credit Packs', style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            SizedBox(height: 12.h),

            // Packs
            _buildPackItem('Starter Pack', 25, 1.99, controller),
            _buildPackItem('Creator Pack (Popular)', 70, 4.99, controller, isHighlight: true),
            _buildPackItem('Pro Studio Pack', 250, 14.99, controller),

            SizedBox(height: 24.h),
            Divider(color: AppColors.border, height: 1.h),
            SizedBox(height: 16.h),
            Text(
              'Account & Security',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline, size: 18.sp, color: AppColors.primary),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          Supabase.instance.client.auth.currentUser?.email ?? 'Logged In Creator',
                          style: TextStyle(fontSize: 13.sp, color: AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.accentError.withValues(alpha: 0.5)),
                        foregroundColor: AppColors.accentError,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text('Sign Out', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Get.dialog(
                          AlertDialog(
                            backgroundColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.r),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            title: Text(
                              'Sign Out?',
                              style: TextStyle(color: AppColors.textPrimary, fontSize: 16.sp, fontWeight: FontWeight.bold),
                            ),
                            content: Text(
                              'Are you sure you want to sign out of CraftAI Studio?',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13.sp),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Get.back(),
                                child: Text('Cancel', style: TextStyle(color: AppColors.textMuted, fontSize: 13.sp)),
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
                                child: Text('Sign Out', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackItem(String title, double credits, double price, WalletController ctrl, {bool isHighlight = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isHighlight ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: isHighlight ? AppColors.primary : AppColors.textPrimary)),
              Text('${credits.toInt()} Credits (\$${(price / credits).toStringAsFixed(3)} / Cr)', style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted)),
            ],
          ),
          ElevatedButton(
            onPressed: () => ctrl.buyCreditPack(title, credits, price),
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighlight ? AppColors.primary : AppColors.surfaceLight,
              foregroundColor: isHighlight ? Colors.white : AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('\$$price', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
