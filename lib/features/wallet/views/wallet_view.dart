import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import '../controllers/wallet_controller.dart';

class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final WalletController controller = Get.put(WalletController());

    return Scaffold(
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
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
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
                          foregroundColor: Colors.black,
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
              foregroundColor: isHighlight ? Colors.black : AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text('\$$price', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
