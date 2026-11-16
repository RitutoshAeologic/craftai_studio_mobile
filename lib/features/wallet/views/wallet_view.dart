import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../data/models/credit_package_model.dart';
import '../../../data/models/wallet_ledger_model.dart';
import '../controllers/wallet_controller.dart';
import '../../../shared/widgets/interactions/bouncy_tap.dart';

/// [WalletView] displays the user's total credits, free vs purchased balance breakdown,
/// dynamic credit packages loaded from Supabase Dashboard, native Razorpay payment checkout,
/// and itemized credit passbook ledger history.
class WalletView extends StatelessWidget {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final WalletController controller = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : Get.put(WalletController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textPrimary, size: 18.sp),
                onPressed: () => Get.back(),
              )
            : null,
        title: Text(
          'Wallet & Credits',
          style: AppTextStyles.h2,
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Refresh Balance',
            icon: Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary, size: 20.sp),
            onPressed: () {
              controller.shellCtrl.fetchWalletCredits();
              controller.fetchPackages();
              controller.fetchLedgerEntries();
            },
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.border, height: 1.h),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await controller.shellCtrl.fetchWalletCredits();
              await controller.fetchPackages();
              await controller.fetchLedgerEntries();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics()),
              padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 36.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // =========================================================
                  // 1. TOTAL CREDIT BALANCE & DUAL POOL OVERVIEW
                  // =========================================================
                  _buildBalanceOverviewCard(controller),

                  SizedBox(height: 24.h),

                  // =========================================================
                  // 2. DYNAMIC TOP-UP PACKAGES (RAZORPAY POWERED)
                  // =========================================================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Buy Credit Packs',
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusRound),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded,
                                size: 12.sp, color: AppColors.primary),
                            SizedBox(width: 3.w),
                            Text(
                              'Instant UPI & Cards',
                              style: AppTextStyles.captionBold.copyWith(
                                color: AppColors.primary,
                                fontSize: 10.5.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  Obx(() {
                    if (controller.isLoadingPackages.value &&
                        controller.packages.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: controller.packages.map((pkg) {
                        return _buildDynamicPackageCard(pkg, controller);
                      }).toList(),
                    );
                  }),

                  SizedBox(height: 24.h),
                  Divider(color: AppColors.border, height: 1.h),
                  SizedBox(height: 16.h),

                  // =========================================================
                  // 3. RECENT CREDIT ACTIVITY / PASSBOOK LEDGER
                  // =========================================================
                  Text(
                    'Recent Credit Activity',
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  Obx(() {
                    if (controller.isLoadingLedger.value &&
                        controller.ledgerEntries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.h),
                          child: const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      );
                    }

                    if (controller.ledgerEntries.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                            vertical: 24.h, horizontal: 16.w),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius:
                              BorderRadius.circular(AppDimens.radiusMd),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.receipt_long_rounded,
                                size: 32.sp, color: AppColors.textMuted),
                            SizedBox(height: 8.h),
                            Text(
                              'No recent credit transactions',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Column(
                      children: controller.ledgerEntries.map((entry) {
                        return _buildLedgerItem(entry);
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Payment Processing / Verifying Overlay
          Obx(() {
            if (!controller.isVerifyingPayment.value) {
              return const SizedBox.shrink();
            }

            return Container(
              color: Colors.black.withValues(alpha: 0.65),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppDimens.radiusLg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Verifying payment with bank...',
                        style: AppTextStyles.bodyMediumBold
                            .copyWith(color: AppColors.textPrimary),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Synchronizing your cloud credit balance atomically.',
                        style: AppTextStyles.caption
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Total balance & Breakdown overview
  Widget _buildBalanceOverviewCard(WalletController controller) {
    return Obx(() {
      final wallet = controller.wallet.value;
      final totalCredits = wallet.totalBalance;

      return Container(
        padding: EdgeInsets.all(18.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surface,
              AppColors.surfaceLight.withValues(alpha: 0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppDimens.radiusLg),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.04),
              blurRadius: 10.r,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Credit Balance',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11.5.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            totalCredits.toInt().toString(),
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 32.sp,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'Credits',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: AppColors.aiCosmicGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 10.r,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 22.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Divider(color: AppColors.border, height: 1.h),
            SizedBox(height: 12.h),

            // Free vs Purchased Breakdown
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Purchased Credits',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${wallet.purchasedBalance.toInt()} Cr',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1.w,
                  height: 28.h,
                  color: AppColors.border,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Creator Royalties',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${wallet.earnedRoyaltyBalance.toStringAsFixed(1)} Cr',
                        style: TextStyle(
                          color: AppColors.accentSuccess,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (wallet.earnedRoyaltyBalance > 0) ...[
              SizedBox(height: 12.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cash Value: ₹${(wallet.earnedRoyaltyBalance * 0.50).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5.sp,
                    ),
                  ),
                  BouncyTap(
                    onTap: controller.requestPayout,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusRound),
                      ),
                      child: Text(
                        'Withdraw Payout',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Dynamic Top-Up Card rendered with Supabase Dashboard data
  Widget _buildDynamicPackageCard(
      CreditPackageModel pkg, WalletController ctrl) {
    final isPopular = pkg.isPopular;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        border: Border.all(
          color: isPopular ? AppColors.primary : AppColors.border,
          width: isPopular ? 1.5.w : 1.w,
        ),
        boxShadow: isPopular
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10.r,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Ribbon (if badge exists)
          if (pkg.badge != null && pkg.badge!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
              decoration: BoxDecoration(
                gradient: isPopular
                    ? AppColors.aiCosmicGradient
                    : LinearGradient(
                        colors: [AppColors.primary, AppColors.card],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.radiusLg - 1),
                  topRight: Radius.circular(AppDimens.radiusLg - 1),
                ),
              ),
              child: Text(
                pkg.badge!.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pkg.name,
                        style: AppTextStyles.bodyMediumBold.copyWith(
                          color: isPopular
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 14.5.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6.w,
                        children: [
                          Text(
                            '${pkg.totalCredits} Credits',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (pkg.bonusCredits > 0)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.accentSuccess
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                '+${pkg.bonusCredits} Free',
                                style: TextStyle(
                                  color: AppColors.accentSuccess,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '(${pkg.effectiveRate})',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // 1-Tap Razorpay Button with Inline Loader & Race Guard
                Obx(() {
                  final isThisPurchasing =
                      ctrl.purchasingPackageId.value == pkg.packageId;
                  final isAnyPurchasing = ctrl.isPurchasing.value;

                  return BouncyTap(
                    onTap: isAnyPurchasing ? null : () => ctrl.initiatePurchase(pkg),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 18.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        gradient: isPopular ? AppColors.aiCosmicGradient : null,
                        color: isPopular ? null : AppColors.surfaceLight,
                        borderRadius:
                            BorderRadius.circular(AppDimens.radiusRound),
                        border: Border.all(
                          color: isPopular
                              ? Colors.transparent
                              : AppColors.border,
                          width: 1.w,
                        ),
                        boxShadow: isPopular
                            ? [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8.r,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isThisPurchasing
                          ? SizedBox(
                              width: 32.w,
                              height: 18.h,
                              child: Center(
                                child: SizedBox(
                                  width: 14.sp,
                                  height: 14.sp,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: isPopular
                                        ? Colors.white
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  pkg.formattedPriceInr,
                                  style: TextStyle(
                                    color: isPopular
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Itemized passbook ledger entry
  Widget _buildLedgerItem(WalletLedgerModel entry) {
    final isCredit = entry.isCredit;
    final dateStr = DateFormat('MMM d, h:mm a').format(entry.createdAt);

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isCredit
                  ? AppColors.accentSuccess.withValues(alpha: 0.12)
                  : AppColors.textSecondary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCredit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: isCredit
                  ? AppColors.accentSuccess
                  : AppColors.textSecondary,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  style: AppTextStyles.bodyMediumBold.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 12.5.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  dateStr,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.5.sp,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isCredit ? '+' : ''}${entry.amount.toInt()} Cr',
            style: TextStyle(
              color: isCredit
                  ? AppColors.accentSuccess
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 13.5.sp,
            ),
          ),
        ],
      ),
    );
  }
}
