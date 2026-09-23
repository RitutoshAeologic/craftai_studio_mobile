import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class ForgotPasswordView extends StatelessWidget {
  const ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          _buildGlow(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ────────────────────────────────────────────
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ctrl.clearError();
                          ctrl.emailCtrl.clear();
                          Get.back();
                        },
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textSecondary,
                          size: 20.r,
                        ),
                      ),
                    ],
                  ),
                ),
                // ── Content ────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 20.h),
                        _buildHeader(),
                        SizedBox(height: 40.h),
                        Form(
                          key: ctrl.forgotFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Obx(
                                () => AppTextField(
                                  controller: ctrl.emailCtrl,
                                  label: 'Email address',
                                  hintText: 'you@example.com',
                                  prefixIcon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.done,
                                  autofocus: true,
                                  autovalidateMode:
                                      AutovalidateMode.onUserInteraction,
                                  onSubmitted: (_) => ctrl.sendPasswordReset(),
                                  validator: AuthController.validateEmail,
                                  suffixIcon: ctrl.isEmailValid.value
                                      ? Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.accentSuccess,
                                          size: 20.r,
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'We\'ll send a secure reset link to this address. '
                                'Check your spam folder if it doesn\'t arrive within '
                                'a few minutes.',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 32.h),
                              // ── Error banner ─────────────────────────────
                              Obx(() {
                                final msg = ctrl.errorMessage.value;
                                if (msg.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: _ErrorBanner(message: msg),
                                );
                              }),
                              // ── Send button ───────────────────────────────
                              Obx(
                                () => _PrimaryButton(
                                  label: 'Send Reset Link',
                                  isLoading: ctrl.isLoading.value,
                                  isValid: ctrl.isForgotFormValid.value,
                                  onTap: ctrl.sendPasswordReset,
                                ),
                              ),
                              SizedBox(height: 32.h),
                              // ── Back to sign in ───────────────────────────
                              Center(
                                child: GestureDetector(
                                  onTap: () {
                                    ctrl.clearError();
                                    ctrl.emailCtrl.clear();
                                    Get.back();
                                  },
                                  child: Text(
                                    '← Back to Sign In',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── UI helpers ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54.w,
          height: 54.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: AppColors.surfaceLight,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(
            Icons.lock_reset_rounded,
            size: 28.r,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 22.h),
        Text(
          'Reset password',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Enter your email and we\'ll send you a link',
          style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildGlow() => Positioned(
        top: -120,
        left: -80,
        child: Container(
          width: 350,
          height: 350,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      );
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
    this.isValid = true,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: LinearGradient(
            colors: isLoading
                ? [
                    AppColors.primary.withValues(alpha: 0.5),
                    AppColors.secondary.withValues(alpha: 0.5),
                  ]
                : (isValid
                    ? [AppColors.primary, AppColors.secondary]
                    : [
                        AppColors.primary.withValues(alpha: 0.7),
                        AppColors.secondary.withValues(alpha: 0.7)
                      ]),
          ),
          boxShadow: isLoading || !isValid
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.38),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 22.w,
                  height: 22.w,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.accentError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.accentError.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.accentError, size: 18.r),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(message,
                style:
                    TextStyle(fontSize: 13.sp, color: AppColors.accentError)),
          ),
        ],
      ),
    );
  }
}
