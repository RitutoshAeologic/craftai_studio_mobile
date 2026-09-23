import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_user_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_logger.dart';

/// Return type for sign-in operations.
typedef AuthResult = ({AuthUserModel? user, AuthFailure? failure});

/// Return type for sign-up (includes email-confirmation flag).
typedef SignUpResult = ({
  AuthUserModel? user,
  bool emailConfirmationRequired,
  AuthFailure? failure,
});

/// All Supabase Auth calls live here. Controllers never touch
/// [SupabaseClient] directly — per rules.md §1 "client is UI only".
class AuthRepository {
  SupabaseClient get _client => SupabaseService.client;

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Returns the currently signed-in user or null.
  AuthUserModel? get currentUser {
    final user = _client.auth.currentUser;
    return user != null ? AuthUserModel.fromSupabaseUser(user) : null;
  }

  /// Broadcasts every [AuthChangeEvent] (signedIn, signedOut, userUpdated…).
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Write ─────────────────────────────────────────────────────────────────

  /// Sign in with email + password.
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    AppLogger.i('Attempting sign-in for email: "$cleanEmail"', tag: 'AUTH');
    try {
      final res = await _client.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      final user = res.user;
      if (user == null) {
        AppLogger.w('Sign-in returned null user for: $cleanEmail', tag: 'AUTH');
        return (user: null, failure: const InvalidCredentials());
      }
      AppLogger.s('Sign-in successful for user ID: ${user.id} ($cleanEmail)', tag: 'AUTH');
      return (user: AuthUserModel.fromSupabaseUser(user), failure: null);
    } on AuthException catch (e, st) {
      AppLogger.e('Supabase AuthException on sign-in: [${e.statusCode}] ${e.message}', tag: 'AUTH', error: e, stackTrace: st);
      return (user: null, failure: _mapException(e));
    } catch (e, st) {
      AppLogger.e('Unexpected non-auth exception during sign-in: $e', tag: 'AUTH', error: e, stackTrace: st);
      return (user: null, failure: const NetworkFailure());
    }
  }

  /// Register a new account with email + password.
  /// When Supabase email confirmation is enabled, [emailConfirmationRequired]
  /// will be true and the user must verify before signing in.
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final cleanEmail = email.trim();
    AppLogger.i('Attempting sign-up for email: "$cleanEmail"', tag: 'AUTH');
    try {
      final res = await _client.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
        },
      );
      final user = res.user;
      if (user == null) {
        AppLogger.w('Sign-up returned null user for: $cleanEmail', tag: 'AUTH');
        return (
          user: null,
          emailConfirmationRequired: false,
          failure: const UnknownFailure('Sign-up failed. Please try again.'),
        );
      }
      AppLogger.s('Sign-up successful for user ID: ${user.id} ($cleanEmail)', tag: 'AUTH');
      // session == null  →  Supabase is waiting for email confirmation.
      return (
        user: AuthUserModel.fromSupabaseUser(user),
        emailConfirmationRequired: res.session == null,
        failure: null,
      );
    } on AuthException catch (e, st) {
      AppLogger.e('Supabase AuthException on sign-up: [${e.statusCode}] ${e.message}', tag: 'AUTH', error: e, stackTrace: st);
      return (
        user: null,
        emailConfirmationRequired: false,
        failure: _mapException(e),
      );
    } catch (e, st) {
      AppLogger.e('Unexpected non-auth exception during sign-up: $e', tag: 'AUTH', error: e, stackTrace: st);
      return (
        user: null,
        emailConfirmationRequired: false,
        failure: const NetworkFailure(),
      );
    }
  }

  /// Send a password-reset link to [email].
  /// Returns null on success, or a typed [AuthFailure].
  Future<AuthFailure?> sendPasswordResetEmail(String email) async {
    final cleanEmail = email.trim();
    AppLogger.i('Sending password reset email to: "$cleanEmail"', tag: 'AUTH');
    try {
      await _client.auth.resetPasswordForEmail(cleanEmail);
      AppLogger.s('Password reset email dispatched to: "$cleanEmail"', tag: 'AUTH');
      return null;
    } on AuthException catch (e, st) {
      AppLogger.e('Supabase AuthException on reset password: [${e.statusCode}] ${e.message}', tag: 'AUTH', error: e, stackTrace: st);
      return _mapException(e);
    } catch (e, st) {
      AppLogger.e('Unexpected non-auth exception during reset password: $e', tag: 'AUTH', error: e, stackTrace: st);
      return const NetworkFailure();
    }
  }

  /// Sign the current user out and clear the local session.
  Future<void> signOut() async {
    AppLogger.i('Signing out user...', tag: 'AUTH');
    try {
      await _client.auth.signOut();
      AppLogger.s('User signed out successfully', tag: 'AUTH');
    } catch (e, st) {
      AppLogger.e('Error during sign out: $e', tag: 'AUTH', error: e, stackTrace: st);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  AuthFailure _mapException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('wrong password') ||
        msg.contains('incorrect password')) {
      return const InvalidCredentials();
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered') ||
        msg.contains('already registered')) {
      return const EmailAlreadyInUse();
    }
    if (msg.contains('password should be at least') ||
        msg.contains('weak password') ||
        msg.contains('password is too short')) {
      return const WeakPassword();
    }
    if (msg.contains('email not confirmed')) {
      return const EmailNotConfirmed();
    }
    if (msg.contains('user not found') || msg.contains('no user found')) {
      return const UserNotFound();
    }
    return UnknownFailure(e.message);
  }
}
