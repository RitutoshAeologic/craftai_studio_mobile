import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimens.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/profile_controller.dart';

/// [ProfileView] displays full creator account credentials, active session status,
/// wallet balance quick-link, system information, and sign-out actions.
class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ProfileController controller = Get.put(ProfileController());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profile',
          style: AppTextStyles.h1,
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: AppColors.border,
            height: 1.h,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppDimens.spacingLg,
          vertical: AppDimens.vSpacingXl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =========================================================================
            // 1. CREATOR HERO CARD
            // =========================================================================
            _buildCreatorHeroCard(controller),
            SizedBox(height: AppDimens.vSpacingXl),

            // =========================================================================
            // 2. WALLET & CREDITS SHORTCUT CARD
            // =========================================================================
            _buildWalletQuickCard(controller),
            SizedBox(height: AppDimens.vSpacingXl),

            // =========================================================================
            // 3. ACCOUNT & SESSION SECTION (FROM BOTTOM SHEET)
            // =========================================================================
            Text(
              'Account & Session',
              style: AppTextStyles.h2,
            ),
            SizedBox(height: AppDimens.vSpacingMd),
            _buildAccountDetailsCard(controller),
            SizedBox(height: AppDimens.vSpacingXl),

            // =========================================================================
            // 4. APP & SYSTEM INFO
            // =========================================================================
            Text(
              'About CraftAI Studio',
              style: AppTextStyles.h2,
            ),
            SizedBox(height: AppDimens.vSpacingMd),
            _buildAppInfoCard(),
            SizedBox(height: AppDimens.vSpacingXl),

            // =========================================================================
            // 5. SIGN OUT ACTION (FROM BOTTOM SHEET)
            // =========================================================================
            _buildSignOutTile(controller),
            SizedBox(height: AppDimens.vSpacingXxl),
          ],
        ),
      ),
    );
  }

  /// Displays avatar, display name, email, and verified status badges.
  Widget _buildCreatorHeroCard(ProfileController controller) {
    return Container(
      padding: EdgeInsets.all(AppDimens.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar circle with initial letter
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2.w),
            ),
            child: Center(
              child: Text(
                controller.email.isNotEmpty
                    ? controller.email[0].toUpperCase()
                    : 'C',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: AppDimens.spacingLg),

          // User name, email and creator badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        controller.displayName,
                        style: AppTextStyles.h2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: AppColors.accentSuccess.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Creator',
                        style: TextStyle(
                          color: AppColors.accentSuccess,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  controller.email,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 6.h),
                Row(
                  children: [
                    Container(
                      width: 7.w,
                      height: 7.w,
                      decoration: const BoxDecoration(
                        color: AppColors.accentSuccess,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      'Session Active',
                      style: AppTextStyles.captionXs.copyWith(
                        color: AppColors.accentSuccess,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Quick balance display and navigation to full Wallet & Packs page
  Widget _buildWalletQuickCard(ProfileController controller) {
    return Container(
      padding: EdgeInsets.all(AppDimens.spacingLg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        'Wallet & Credits',
                        style: AppTextStyles.bodyMediumBold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Obx(() => Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppDimens.radiusRound),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${controller.shellController.userCredits.value.toStringAsFixed(0)} Cr',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Credits are used for studio GPU generation, Copilot prompt refines, and AI editing.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: 14.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: controller.openWallet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 10.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimens.radiusMd),
                ),
              ),
              icon: Icon(Icons.flash_on, size: 16.sp, color: Colors.amber),
              label: Text(
                'Open Wallet & Top Up Credits',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Account information details (matches and expands bottom sheet items)
  Widget _buildAccountDetailsCard(ProfileController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Email item
          _buildInfoRow(
            icon: Icons.email_outlined,
            title: 'Email Address',
            value: controller.email,
            trailingWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: controller.isEmailConfirmed
                        ? AppColors.accentSuccess.withValues(alpha: 0.12)
                        : AppColors.accentWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    controller.isEmailConfirmed ? 'Verified' : 'Unconfirmed',
                    style: TextStyle(
                      color: controller.isEmailConfirmed
                          ? AppColors.accentSuccess
                          : AppColors.accentWarning,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 6.w),
                GestureDetector(
                  onTap: () => controller.copyToClipboard(controller.email, 'Email'),
                  child: Icon(Icons.copy_rounded, size: 16.sp, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.border, height: 1.h),

          // User ID item
          _buildInfoRow(
            icon: Icons.fingerprint_rounded,
            title: 'Account ID',
            value: controller.maskedUserId,
            trailingWidget: GestureDetector(
              onTap: () => controller.copyToClipboard(controller.userId, 'User ID'),
              child: Icon(Icons.copy_rounded, size: 16.sp, color: AppColors.textMuted),
            ),
          ),
          Divider(color: AppColors.border, height: 1.h),

          // Session Status item
          _buildInfoRow(
            icon: Icons.lock_outline_rounded,
            title: 'Session Status',
            value: 'Authenticated & Encrypted',
            trailingWidget: Icon(Icons.verified_user_outlined, size: 16.sp, color: AppColors.accentSuccess),
          ),
          Divider(color: AppColors.border, height: 1.h),

          // Member Since item
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Member Since',
            value: controller.memberSinceFormatted,
          ),
        ],
      ),
    );
  }

  /// App info card
  Widget _buildAppInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            value: '1.0.0 (Production Build)',
          ),
          Divider(color: AppColors.border, height: 1.h),
          _buildInfoRow(
            icon: Icons.cloud_done_outlined,
            title: 'AI Processing Engine',
            value: 'FastAPI GPU Cloud Services',
          ),
        ],
      ),
    );
  }

  /// Sign out ListTile matching the exact functionality and text from the bottom sheet
  Widget _buildSignOutTile(ProfileController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusXl),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
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
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: AppColors.accentError,
          size: 20.sp,
        ),
        onTap: controller.confirmSignOut,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 18.sp, color: AppColors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: AppTextStyles.bodyMediumBold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailingWidget != null) trailingWidget,
        ],
      ),
    );
  }
}
