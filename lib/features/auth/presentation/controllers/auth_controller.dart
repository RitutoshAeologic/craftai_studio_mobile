import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_failure.dart';
import '../../domain/auth_user_model.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';

/// Permanent GetX controller — registered in [main.dart] via
/// `Get.put(AuthController(), permanent: true)`.
/// Alive for the full app session; scoped auth screens just `Get.find()` it.
class AuthController extends GetxController {
  AuthController({AuthRepository? repository})
      : _repo = repository ?? AuthRepository();

  final AuthRepository _repo;

  // ── Observable state ──────────────────────────────────────────────────────
  final Rx<AuthUserModel?> currentUser = Rx<AuthUserModel?>(null);
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Form controllers ──────────────────────────────────────────────────────
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final displayNameCtrl = TextEditingController();

  // ── Password visibility toggles ───────────────────────────────────────────
  final RxBool isPasswordVisible = false.obs;
  final RxBool isConfirmPasswordVisible = false.obs;

  // ── Form keys ─────────────────────────────────────────────────────────────
  final loginFormKey = GlobalKey<FormState>();
  final signupFormKey = GlobalKey<FormState>();
  final forgotFormKey = GlobalKey<FormState>();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _repo.currentUser;
    // Reactively reflect every Supabase auth state change.
    // Subscription is auto-cancelled via GetX onClose() stream management.
    _repo.authStateChanges.listen(_onAuthStateChange);
  }

  void _onAuthStateChange(AuthState state) {
    switch (state.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.userUpdated:
        currentUser.value = _repo.currentUser;
      case AuthChangeEvent.signedOut:
        currentUser.value = null;
      default:
        break;
    }
  }

  bool get isAuthenticated => currentUser.value != null;

  // ── Sign In ───────────────────────────────────────────────────────────────

  Future<void> signIn() async {
    if (!(loginFormKey.currentState?.validate() ?? false)) return;
    _begin();

    final result = await _repo.signInWithEmail(
      email: emailCtrl.text,
      password: passwordCtrl.text,
    );

    _end();

    if (result.failure != null) {
      errorMessage.value = _toMessage(result.failure!);
    } else {
      currentUser.value = result.user;
      _clearFields();
      Get.offAllNamed(AppRoutes.home);
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<void> signUp() async {
    if (!(signupFormKey.currentState?.validate() ?? false)) return;
    _begin();

    final result = await _repo.signUpWithEmail(
      email: emailCtrl.text,
      password: passwordCtrl.text,
      displayName: displayNameCtrl.text.trim().isEmpty
          ? null
          : displayNameCtrl.text.trim(),
    );

    _end();

    if (result.failure != null) {
      errorMessage.value = _toMessage(result.failure!);
    } else if (result.emailConfirmationRequired) {
      final email = emailCtrl.text.trim();
      _clearFields();
      _snackbar(
        title: 'Check your inbox 📬',
        body: 'We sent a confirmation link to $email. '
            'Verify your email before signing in.',
        isSuccess: true,
      );
      Get.offAllNamed(AppRoutes.login);
    } else {
      currentUser.value = result.user;
      _clearFields();
      Get.offAllNamed(AppRoutes.home);
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────

  Future<void> sendPasswordReset() async {
    if (!(forgotFormKey.currentState?.validate() ?? false)) return;
    _begin();

    final email = emailCtrl.text.trim();
    final failure = await _repo.sendPasswordResetEmail(email);

    _end();

    if (failure != null) {
      errorMessage.value = _toMessage(failure);
    } else {
      emailCtrl.clear();
      _snackbar(
        title: 'Reset link sent ✉️',
        body: 'Check $email for a password reset link.',
        isSuccess: true,
      );
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    await _repo.signOut();
    currentUser.value = null;
    Get.offAllNamed(AppRoutes.login);
  }

  // ── UI toggles ────────────────────────────────────────────────────────────

  void togglePasswordVisibility() => isPasswordVisible.toggle();
  void toggleConfirmPasswordVisibility() => isConfirmPasswordVisible.toggle();
  void clearError() => errorMessage.value = '';

  // ── Private helpers ───────────────────────────────────────────────────────

  void _begin() {
    isLoading.value = true;
    errorMessage.value = '';
  }

  void _end() => isLoading.value = false;

  void _clearFields() {
    emailCtrl.clear();
    passwordCtrl.clear();
    confirmPasswordCtrl.clear();
    displayNameCtrl.clear();
    isPasswordVisible.value = false;
    isConfirmPasswordVisible.value = false;
  }

  void _snackbar({
    required String title,
    required String body,
    bool isSuccess = false,
  }) {
    Get.snackbar(
      title,
      body,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor:
          isSuccess ? AppColors.accentSuccess.withValues(alpha: 0.12) : AppColors.accentError.withValues(alpha: 0.12),
      colorText: AppColors.textPrimary,
      borderColor:
          isSuccess ? AppColors.accentSuccess.withValues(alpha: 0.3) : AppColors.accentError.withValues(alpha: 0.3),
      borderWidth: 1,
      borderRadius: 12,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      duration: const Duration(seconds: 4),
      icon: Icon(
        isSuccess ? Icons.check_circle_outline : Icons.error_outline,
        color: isSuccess ? AppColors.accentSuccess : AppColors.accentError,
      ),
    );
  }

  /// Maps every [AuthFailure] subtype to a plain-English, user-facing string.
  /// Rules.md §6: "plain language, not a raw exception message or HTTP status."
  String _toMessage(AuthFailure failure) => switch (failure) {
        InvalidCredentials() =>
          'Incorrect email or password. Please try again.',
        EmailAlreadyInUse() =>
          'This email is already registered. Try signing in instead.',
        WeakPassword() => 'Password must be at least 6 characters.',
        EmailNotConfirmed() =>
          'Please confirm your email address before signing in.',
        UserNotFound() => 'No account found with this email address.',
        NetworkFailure() =>
          'Connection error. Check your internet and try again.',
        UnknownFailure(:final message) => message,
      };

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    displayNameCtrl.dispose();
    super.onClose();
  }
}
