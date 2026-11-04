import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/auth_repository.dart';
import '../../domain/auth_failure.dart';
import '../../domain/auth_user_model.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/network_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../library/controllers/library_controller.dart';
import '../../../library/controllers/collection_controller.dart';
import '../../../studio/presentation/controllers/studio_controller.dart';

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
  final RxBool isSigningOut = false.obs;
  final RxString errorMessage = ''.obs;

  // ── Real-time validation observables ──────────────────────────────────────
  final RxBool isEmailValid = false.obs;
  final RxBool isPasswordValid = false.obs;
  final RxBool isConfirmPasswordValid = false.obs;
  final RxBool hasPasswordText = false.obs;
  final RxBool hasConfirmText = false.obs;
  final RxBool isLoginFormValid = false.obs;
  final RxBool isSignupFormValid = false.obs;
  final RxBool isForgotFormValid = false.obs;

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

  // ── Independent field-level validation keys ───────────────────────────────
  final emailFieldKey = GlobalKey<FormFieldState<String>>();
  final passwordFieldKey = GlobalKey<FormFieldState<String>>();

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    currentUser.value = _repo.currentUser;
    // Reactively reflect every Supabase auth state change.
    // Subscription is auto-cancelled via GetX onClose() stream management.
    _repo.authStateChanges.listen(_onAuthStateChange);

    // Attach independent real-time input change listeners
    emailCtrl.addListener(_onEmailChanged);
    passwordCtrl.addListener(_onPasswordChanged);
    confirmPasswordCtrl.addListener(_onConfirmPasswordChanged);
    displayNameCtrl.addListener(_onDisplayNameChanged);
  }

  void _onEmailChanged() {
    if (errorMessage.value.isNotEmpty) errorMessage.value = '';
    final email = emailCtrl.text.trim();
    isEmailValid.value = isValidEmail(email);
    isLoginFormValid.value = isEmailValid.value && isPasswordValid.value;
    isSignupFormValid.value =
        isEmailValid.value && isPasswordValid.value && isConfirmPasswordValid.value;
    isForgotFormValid.value = isEmailValid.value;
  }

  void _onPasswordChanged() {
    if (errorMessage.value.isNotEmpty) errorMessage.value = '';
    final password = passwordCtrl.text;
    hasPasswordText.value = password.isNotEmpty;
    isPasswordValid.value = isValidPassword(password);
    isConfirmPasswordValid.value = isValidConfirm(confirmPasswordCtrl.text, password);
    isLoginFormValid.value = isEmailValid.value && isPasswordValid.value;
    isSignupFormValid.value =
        isEmailValid.value && isPasswordValid.value && isConfirmPasswordValid.value;
  }

  void _onConfirmPasswordChanged() {
    if (errorMessage.value.isNotEmpty) errorMessage.value = '';
    final confirm = confirmPasswordCtrl.text;
    hasConfirmText.value = confirm.isNotEmpty;
    isConfirmPasswordValid.value = isValidConfirm(confirm, passwordCtrl.text);
    isSignupFormValid.value =
        isEmailValid.value && isPasswordValid.value && isConfirmPasswordValid.value;
  }

  void _onDisplayNameChanged() {
    if (errorMessage.value.isNotEmpty) errorMessage.value = '';
  }

  void _onFieldChanged() {
    _onEmailChanged();
    _onPasswordChanged();
  }

  /// Validates the Email field independently.
  bool validateEmailField() {
    return emailFieldKey.currentState?.validate() ?? isValidEmail(emailCtrl.text.trim());
  }

  /// Validates the Password field independently.
  bool validatePasswordField() {
    return passwordFieldKey.currentState?.validate() ?? isValidPassword(passwordCtrl.text);
  }

  /// Resets independent login form validation states.
  void resetLoginForm() {
    emailFieldKey.currentState?.reset();
    passwordFieldKey.currentState?.reset();
    loginFormKey.currentState?.reset();
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

  // ── Validation Helpers ────────────────────────────────────────────────────

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9_+-]+(?:\.[a-zA-Z0-9_+-]+)*@(?:[a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$',
  );

  static bool isValidEmail(String? v) {
    if (v == null || v.trim().isEmpty) return false;
    return _emailRegExp.hasMatch(v.trim());
  }

  static bool isValidPassword(String? v) {
    return v != null && v.length >= 6;
  }

  static bool isValidConfirm(String? confirm, String? password) {
    return confirm != null &&
        confirm.isNotEmpty &&
        password != null &&
        confirm == password;
  }

  static String? validateEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!isValidEmail(v)) return 'Enter a valid email address';
    return null;
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (!isValidPassword(v)) return 'Password must be at least 6 characters';
    return null;
  }

  static String? validateConfirm(String? v, String password) {
    if (v == null || v.isEmpty) return 'Please confirm your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }

  // ── Sign In ───────────────────────────────────────────────────────────────

  Future<void> signIn() async {
    // 1. Validate both fields independently so both display their respective errors if invalid
    final isEmailValidNow = emailFieldKey.currentState?.validate() ??
        isValidEmail(emailCtrl.text);
    final isPasswordValidNow = passwordFieldKey.currentState?.validate() ??
        isValidPassword(passwordCtrl.text);

    final formValid = (emailFieldKey.currentState != null || passwordFieldKey.currentState != null)
        ? (isEmailValidNow && isPasswordValidNow)
        : (loginFormKey.currentState?.validate() ??
            (isLoginFormValid.value &&
                isValidEmail(emailCtrl.text) &&
                isValidPassword(passwordCtrl.text)));

    if (!formValid) {
      AppLogger.w(
          'Sign-in form validation failed (invalid email/password format)',
          tag: 'AUTH_UI');
      return;
    }

    if (Get.isRegistered<NetworkService>() && !NetworkService.to.isOnline) {
      AppLogger.w('Sign-in blocked pre-flight: Device is offline', tag: 'AUTH_UI');
      errorMessage.value = 'No internet connection. Please check your network.';
      _snackbar(
        title: 'No Internet Connection 📡',
        body: 'Please check your Wi-Fi or mobile data and try again.',
      );
      return;
    }

    _begin();

    final email = emailCtrl.text.trim();
    AppLogger.i('Sign-in requested for: "$email"', tag: 'AUTH_UI');

    final result = await _repo.signInWithEmail(
      email: email,
      password: passwordCtrl.text,
    );

    _end();

    if (result.failure != null) {
      final msg = _toMessage(result.failure!);
      errorMessage.value = msg;
      AppLogger.e('Sign-in failed for "$email": [${result.failure.runtimeType}] $msg', tag: 'AUTH_UI');
    } else {
      currentUser.value = result.user;
      _clearFields();
      AppLogger.s('User authenticated: ${result.user?.email} -> Navigating to Home', tag: 'AUTH_UI');
      Get.offAllNamed(AppRoutes.home);
    }
  }

  // ── Sign Up ───────────────────────────────────────────────────────────────

  Future<void> signUp() async {
    final formValid = signupFormKey.currentState?.validate() ??
        (isSignupFormValid.value &&
            isValidEmail(emailCtrl.text) &&
            isValidPassword(passwordCtrl.text) &&
            isValidConfirm(confirmPasswordCtrl.text, passwordCtrl.text));

    if (!formValid) {
      AppLogger.w('Sign-up form validation failed', tag: 'AUTH_UI');
      return;
    }

    if (Get.isRegistered<NetworkService>() && !NetworkService.to.isOnline) {
      AppLogger.w('Sign-up blocked pre-flight: Device is offline', tag: 'AUTH_UI');
      errorMessage.value = 'No internet connection. Please check your network.';
      _snackbar(
        title: 'No Internet Connection 📡',
        body: 'Please check your Wi-Fi or mobile data and try again.',
      );
      return;
    }

    _begin();

    final email = emailCtrl.text.trim();
    AppLogger.i('Sign-up requested for: "$email"', tag: 'AUTH_UI');

    final result = await _repo.signUpWithEmail(
      email: email,
      password: passwordCtrl.text,
      displayName: displayNameCtrl.text.trim().isEmpty
          ? null
          : displayNameCtrl.text.trim(),
    );

    _end();

    if (result.failure != null) {
      final msg = _toMessage(result.failure!);
      errorMessage.value = msg;
      AppLogger.e('Sign-up failed for "$email": [${result.failure.runtimeType}] $msg', tag: 'AUTH_UI');
    } else if (result.emailConfirmationRequired) {
      _clearFields();
      AppLogger.s('Sign-up confirmation link sent to "$email"', tag: 'AUTH_UI');
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
      AppLogger.s('User registered & signed in: ${result.user?.email} -> Navigating to Home', tag: 'AUTH_UI');
      Get.offAllNamed(AppRoutes.home);
    }
  }

  // ── Forgot Password ───────────────────────────────────────────────────────

  Future<void> sendPasswordReset() async {
    final formValid = forgotFormKey.currentState?.validate() ??
        (isForgotFormValid.value && isValidEmail(emailCtrl.text));

    if (!formValid) {
      AppLogger.w('Password reset form validation failed', tag: 'AUTH_UI');
      return;
    }

    if (Get.isRegistered<NetworkService>() && !NetworkService.to.isOnline) {
      AppLogger.w('Password reset blocked pre-flight: Device is offline', tag: 'AUTH_UI');
      errorMessage.value = 'No internet connection. Please check your network.';
      _snackbar(
        title: 'No Internet Connection 📡',
        body: 'Please check your Wi-Fi or mobile data and try again.',
      );
      return;
    }

    _begin();

    final email = emailCtrl.text.trim();
    AppLogger.i('Password reset requested for: "$email"', tag: 'AUTH_UI');
    final failure = await _repo.sendPasswordResetEmail(email);

    _end();

    if (failure != null) {
      final msg = _toMessage(failure);
      errorMessage.value = msg;
      AppLogger.e('Password reset failed for "$email": [${failure.runtimeType}] $msg', tag: 'AUTH_UI');
    } else {
      emailCtrl.clear();
      AppLogger.s('Password reset link sent to "$email"', tag: 'AUTH_UI');
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
    if (isSigningOut.value) {
      AppLogger.w('Sign-out already in progress, ignoring duplicate call', tag: 'AUTH_UI');
      return;
    }

    isSigningOut.value = true;
    AppLogger.i('Signing out user: ${currentUser.value?.email ?? "anonymous"}', tag: 'AUTH_UI');

    try {
      try {
        final token = SupabaseService.instance.isInitialized
            ? SupabaseService.client.auth.currentSession?.accessToken
            : null;
        if (token != null && token.isNotEmpty) {
          await ApiClient.instance.post(
            '/auth/signout',
            options: Options(
              connectTimeout: const Duration(milliseconds: 1500),
              receiveTimeout: const Duration(milliseconds: 1500),
            ),
          );
        }
      } catch (e) {
        AppLogger.w('Backend signout notification notice: $e', tag: 'AUTH_UI');
      }

      await _repo.signOut();
      currentUser.value = null;

      // Clear in-memory state across active controllers to prevent cross-account session leakage
      if (Get.isRegistered<LibraryController>()) {
        Get.find<LibraryController>().clearLocalData();
      }
      if (Get.isRegistered<CollectionController>()) {
        Get.find<CollectionController>().clearLocalData();
      }
      if (Get.isRegistered<StudioController>()) {
        Get.find<StudioController>().clearSession();
      }

      AppLogger.s('User signed out -> Navigating to Login', tag: 'AUTH_UI');
      Get.offAllNamed(AppRoutes.login);
    } catch (e, st) {
      AppLogger.e('Sign-out error: $e', tag: 'AUTH_UI', error: e, stackTrace: st);
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
      Get.snackbar(
        'Sign Out Failed',
        'Could not complete sign out. Please check your network and try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.surface,
        colorText: AppColors.accentError,
        borderColor: AppColors.accentError.withValues(alpha: 0.3),
        borderWidth: 1,
        borderRadius: 12,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );
    } finally {
      isSigningOut.value = false;
    }
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
    isEmailValid.value = false;
    isPasswordValid.value = false;
    isConfirmPasswordValid.value = false;
    hasPasswordText.value = false;
    hasConfirmText.value = false;
    isLoginFormValid.value = false;
    isSignupFormValid.value = false;
    isForgotFormValid.value = false;
    emailFieldKey.currentState?.reset();
    passwordFieldKey.currentState?.reset();
  }

  void _snackbar({
    required String title,
    required String body,
    bool isSuccess = false,
  }) {
    if (Get.context == null && Get.overlayContext == null) return;
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
    emailCtrl.removeListener(_onFieldChanged);
    passwordCtrl.removeListener(_onFieldChanged);
    confirmPasswordCtrl.removeListener(_onFieldChanged);
    displayNameCtrl.removeListener(_onFieldChanged);

    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmPasswordCtrl.dispose();
    displayNameCtrl.dispose();
    super.onClose();
  }
}
