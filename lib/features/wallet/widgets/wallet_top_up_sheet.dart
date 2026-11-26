import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_dimens.dart';
import 'package:craftai_studio_mobile/core/constants/app_text_styles.dart';
import 'package:craftai_studio_mobile/core/routes/app_routes.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/wallet/controllers/wallet_controller.dart';

/// Modal bottom sheet presented on HTTP 402 Insufficient Credits so users can
/// top up their wallet immediately without losing their Studio prompt/selections.
class WalletTopUpSheet extends StatelessWidget {
  final String? message;

  const WalletTopUpSheet({super.key, this.message});

  static void show({String? message}) {
    if (Platform.environment.containsKey('FLUTTER_TEST') && Get.context == null) {
      return;
    }
    Get.bottomSheet(
      WalletTopUpSheet(message: message),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final walletCtrl = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : Get.put(WalletController());
    final shellCtrl = Get.isRegistered<ShellController>()
        ? Get.find<ShellController>()
        : null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.radiusXl)),
        border: Border.all(color: AppColors.border),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDimens.spacingLg,
        AppDimens.spacingMd,
        AppDimens.spacingLg,
        AppDimens.spacingXl,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: AppDimens.vSpacingMd),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: AppColors.accentWarning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.accentWarning,
                    size: 22.sp,
                  ),
                ),
                SizedBox(width: AppDimens.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Top Up Wallet', style: AppTextStyles.h3),
                      if (shellCtrl != null)
                        Obx(() => Text(
                              'Current balance: ${shellCtrl.userCredits.value.toStringAsFixed(0)} Cr',
                              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                            )),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textMuted, size: AppDimens.iconSm),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            SizedBox(height: AppDimens.vSpacingSm),
            Text(
              message ?? 'Insufficient credits to run this generation. Select a credit pack below to continue.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            SizedBox(height: AppDimens.vSpacingMd),
            _buildQuickPack(
              title: 'Starter Pack',
              credits: 100,
              price: 1.99,
              controller: walletCtrl,
            ),
            _buildQuickPack(
              title: 'Creator Pack (Popular)',
              credits: 300,
              price: 4.99,
              controller: walletCtrl,
              isHighlight: true,
            ),
            _buildQuickPack(
              title: 'Pro Studio Pack',
              credits: 750,
              price: 9.99,
              controller: walletCtrl,
            ),
            SizedBox(height: AppDimens.vSpacingSm),
            OutlinedButton(
              onPressed: () {
                Get.back();
                Get.toNamed(AppRoutes.wallet);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textPrimary,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusMd)),
              ),
              child: Text('Open Full Wallet & Royalties', style: AppTextStyles.captionBold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPack({
    required String title,
    required double credits,
    required double price,
    required WalletController controller,
    bool isHighlight = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppDimens.vSpacingSm),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: isHighlight ? AppColors.primary : AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: isHighlight ? AppColors.primary : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${credits.toInt()} Credits',
                  style: AppTextStyles.captionXs.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          SizedBox(width: AppDimens.spacingSm),
          ElevatedButton(
            onPressed: () {
              controller.buyCreditPack(title, credits, price);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isHighlight ? AppColors.primary : AppColors.surface,
              foregroundColor: isHighlight ? Colors.white : AppColors.textPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSm)),
            ),
            child: Text('\$${price.toStringAsFixed(2)}', style: AppTextStyles.captionBold),
          ),
        ],
      ),
    );
  }
}
