import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../controllers/auth_controller.dart';

class LoginView extends StatelessWidget {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const _BackgroundGlows(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 56.h),
                  _buildHeader(),
                  SizedBox(height: 44.h),
                  Form(
                    key: ctrl.loginFormKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Email ──────────────────────────────────────────
                        Obx(
                          () => AppTextField(
                            controller: ctrl.emailCtrl,
                            label: 'Email',
                            hintText: 'you@example.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
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
                        SizedBox(height: 16.h),
                        // ── Password ───────────────────────────────────────
                        Obx(
                          () => AppTextField(
                            controller: ctrl.passwordCtrl,
                            label: 'Password',
                            hintText: '••••••••',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: !ctrl.isPasswordVisible.value,
                            textInputAction: TextInputAction.done,
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onSubmitted: (_) => ctrl.signIn(),
                            validator: AuthController.validatePassword,
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
                        SizedBox(height: 12.h),
                        // ── Forgot password ────────────────────────────────
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              ctrl.clearError();
                              Get.toNamed(AppRoutes.forgotPassword);
                            },
                            child: Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 28.h),
                        // ── Error banner ───────────────────────────────────
                        Obx(() {
                          final msg = ctrl.errorMessage.value;
                          if (msg.isEmpty) return const SizedBox.shrink();
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: _ErrorBanner(message: msg),
                          );
                        }),
                        // ── Sign In button ─────────────────────────────────
                        Obx(
                          () => _PrimaryButton(
                            label: 'Sign In',
                            isLoading: ctrl.isLoading.value,
                            isValid: ctrl.isLoginFormValid.value,
                            onTap: ctrl.signIn,
                          ),
                        ),
                        SizedBox(height: 36.h),
                        // ── Sign up link ───────────────────────────────────
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                ctrl.clearError();
                                Get.toNamed(AppRoutes.signup);
                              },
                              child: Text(
                                'Sign Up',
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
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 54.w,
          height: 54.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.vip],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.38),
                blurRadius: 22,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: 28.r,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 22.h),
        Text(
          'Welcome back',
          style: TextStyle(
            fontSize: 30.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          'Sign in to continue creating',
          style: TextStyle(fontSize: 15.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ── Private reusable sub-widgets ─────────────────────────────────────────────

class _BackgroundGlows extends StatelessWidget {
  const _BackgroundGlows();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -110.h,
          right: -70.w,
          child: _glow(AppColors.primary, 340),
        ),
        Positioned(
          bottom: -90.h,
          left: -70.w,
          child: _glow(AppColors.secondary, 280),
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
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
        border: Border.all(
          color: AppColors.accentError.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: AppColors.accentError, size: 18.r),
          SizedBox(width: 10.w),
          Flexible(
            child: Text(
              message,
              style:
                  TextStyle(fontSize: 13.sp, color: AppColors.accentError),
            ),
          ),
        ],
      ),
    );
  }
}
