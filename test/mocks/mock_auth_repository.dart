import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/features/auth/data/auth_repository.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_failure.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';

class MockAuthRepository extends AuthRepository {
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast(sync: true);

  AuthResult? signInResult;
  SignUpResult? signUpResult;
  AuthFailure? resetPasswordResult;

  int signInCalls = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;

  int signUpCalls = 0;
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpDisplayName;

  int resetPasswordCalls = 0;
  String? lastResetEmail;

  int signOutCalls = 0;

  AuthUserModel? mockCurrentUser;

  @override
  AuthUserModel? get currentUser => mockCurrentUser;

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  void emitAuthState(AuthState state) {
    _authStateController.add(state);
  }

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInCalls++;
    lastSignInEmail = email;
    lastSignInPassword = password;
    return signInResult ??
        (
          user: const AuthUserModel(id: 'user_123', email: 'test@example.com'),
          failure: null,
        );
  }

  @override
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    signUpCalls++;
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpDisplayName = displayName;
    return signUpResult ??
        (
          user: const AuthUserModel(id: 'user_new', email: 'new@example.com'),
          emailConfirmationRequired: false,
          failure: null,
        );
  }

  @override
  Future<AuthFailure?> sendPasswordResetEmail(String email) async {
    resetPasswordCalls++;
    lastResetEmail = email;
    return resetPasswordResult;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    mockCurrentUser = null;
  }

  void dispose() {
    _authStateController.close();
  }
}
