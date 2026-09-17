import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class SignupView extends StatelessWidget {
  const SignupView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGlows(),
          SafeArea(
            child: Column(
              children: [
                // ── Back button ──────────────────────────────────────────────
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          ctrl.clearError();
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
                // ── Scrollable form ──────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: 8.h),
                        _buildHeader(),
                        SizedBox(height: 36.h),
                        Form(
                          key: ctrl.signupFormKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── Display name ─────────────────────────────
                              AppTextField(
                                controller: ctrl.displayNameCtrl,
                                label: 'Display Name (optional)',
                                hintText: 'Your creator name',
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                              ),
                              SizedBox(height: 16.h),
                              // ── Email ─────────────────────────────────────
                              AppTextField(
                                controller: ctrl.emailCtrl,
                                label: 'Email',
                                hintText: 'you@example.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                validator: _validateEmail,
                              ),
                              SizedBox(height: 16.h),
                              // ── Password ──────────────────────────────────
                              Obx(
                                () => AppTextField(
                                  controller: ctrl.passwordCtrl,
                                  label: 'Password',
                                  hintText: '6+ characters',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText: !ctrl.isPasswordVisible.value,
                                  textInputAction: TextInputAction.next,
                                  validator: _validatePassword,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      ctrl.isPasswordVisible.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                      size: 20.r,
                                    ),
                                    onPressed: ctrl.togglePasswordVisibility,
                                  ),
                                ),
                              ),
                              SizedBox(height: 16.h),
                              // ── Confirm password ──────────────────────────
                              Obx(
                                () => AppTextField(
                                  controller: ctrl.confirmPasswordCtrl,
                                  label: 'Confirm Password',
                                  hintText: 'Re-enter password',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  obscureText:
                                      !ctrl.isConfirmPasswordVisible.value,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => ctrl.signUp(),
                                  validator: (v) =>
                                      _validateConfirm(v, ctrl.passwordCtrl.text),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      ctrl.isConfirmPasswordVisible.value
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.textMuted,
                                      size: 20.r,
                                    ),
                                    onPressed:
                                        ctrl.toggleConfirmPasswordVisibility,
                                  ),
                                ),
                              ),
                              SizedBox(height: 28.h),
                              // ── Error banner ──────────────────────────────
                              Obx(() {
                                final msg = ctrl.errorMessage.value;
                                if (msg.isEmpty) return const SizedBox.shrink();
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 16.h),
                                  child: _ErrorBanner(message: msg),
                                );
                              }),
                              // ── Sign Up button ────────────────────────────
                              Obx(
                                () => _PrimaryButton(
                                  label: 'Create Account',
                                  isLoading: ctrl.isLoading.value,
                                  onTap: ctrl.signUp,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              // ── Terms note ────────────────────────────────
                              Text(
                                'By creating an account you agree to our '
                                'Terms of Service and Privacy Policy.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textMuted,
                                  height: 1.5,
                                ),
                              ),
                              SizedBox(height: 36.h),
                              // ── Sign in link ──────────────────────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Already have an account? ',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      ctrl.clearError();
                                      Get.offNamed(AppRoutes.login);
                                    },
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 32.h),
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

  // ── Validators ──────────────────────────────────────────────────────────────

  String? _validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final re = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!re.hasMatch(v.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  String? _validateConfirm(String? v, String password) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create account',
          style: TextStyle(
            fontSize: 30.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Join the CraftAI creator community',
          style:
              TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Private sub-widgets (same as LoginView, DRY via shared file) ─────────────

class _BackgroundGlows extends StatelessWidget {
  const _BackgroundGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80.h,
          left: -60.w,
          child: _glow(AppColors.secondary, 300),
        ),
        Positioned(
          bottom: -100.h,
          right: -70.w,
          child: _glow(AppColors.vip, 280),
        ),
      ],
    );
  }

  Widget _glow(Color color, double size) => Container(
        width: size.w,
        height: size.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.11), Colors.transparent],
          ),
        ),
      );
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

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
                : [AppColors.primary, AppColors.secondary],
          ),
          boxShadow: isLoading
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
