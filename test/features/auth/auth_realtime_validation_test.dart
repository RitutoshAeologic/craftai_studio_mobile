import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/features/auth/data/auth_repository.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_failure.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/views/login_view.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/views/signup_view.dart';

class MockAuthRepository extends AuthRepository {
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  AuthResult? signInResult;
  SignUpResult? signUpResult;

  @override
  AuthUserModel? get currentUser => null;

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return signInResult ??
        (user: null, failure: const InvalidCredentials());
  }

  @override
  Future<SignUpResult> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    return signUpResult ??
        (
          user: null,
          emailConfirmationRequired: false,
          failure: const EmailAlreadyInUse(),
        );
  }

  void dispose() {
    _authStateController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;
  late AuthController controller;

  setUp(() {
    Get.testMode = true;
    mockRepo = MockAuthRepository();
    controller = AuthController(repository: mockRepo);
    Get.put<AuthController>(controller);
  });

  tearDown(() {
    mockRepo.dispose();
    Get.reset();
  });

  group('AuthController Real-Time Validation Unit Tests', () {
    test('Email validation updates reactively on keystrokes', () {
      expect(controller.isEmailValid.value, isFalse);

      // Incomplete email
      controller.emailCtrl.text = 'test';
      expect(controller.isEmailValid.value, isFalse);

      controller.emailCtrl.text = 'test@';
      expect(controller.isEmailValid.value, isFalse);

      controller.emailCtrl.text = 'test@domain';
      expect(controller.isEmailValid.value, isFalse);

      // Complete valid email
      controller.emailCtrl.text = 'test@domain.com';
      expect(controller.isEmailValid.value, isTrue);

      // With spaces, trimmed is valid
      controller.emailCtrl.text = '  hello@world.io  ';
      expect(controller.isEmailValid.value, isTrue);

      // Cleared back to empty
      controller.emailCtrl.text = '';
      expect(controller.isEmailValid.value, isFalse);
    });

    test('Password validation updates reactively on length boundary (6 chars)', () {
      expect(controller.isPasswordValid.value, isFalse);

      controller.passwordCtrl.text = '12345';
      expect(controller.isPasswordValid.value, isFalse);

      // Exactly 6 chars
      controller.passwordCtrl.text = '123456';
      expect(controller.isPasswordValid.value, isTrue);

      // 7 chars
      controller.passwordCtrl.text = '1234567';
      expect(controller.isPasswordValid.value, isTrue);

      // Backspace to 5
      controller.passwordCtrl.text = '12345';
      expect(controller.isPasswordValid.value, isFalse);
    });

    test('Confirm password reacts to both confirm and primary password changes', () {
      controller.passwordCtrl.text = 'secret123';
      expect(controller.isConfirmPasswordValid.value, isFalse);

      // Partial match
      controller.confirmPasswordCtrl.text = 'secret';
      expect(controller.isConfirmPasswordValid.value, isFalse);

      // Exact match
      controller.confirmPasswordCtrl.text = 'secret123';
      expect(controller.isConfirmPasswordValid.value, isTrue);

      // Primary password modified afterwards
      controller.passwordCtrl.text = 'secret1234';
      expect(controller.isConfirmPasswordValid.value, isFalse);

      // Fixed again
      controller.confirmPasswordCtrl.text = 'secret1234';
      expect(controller.isConfirmPasswordValid.value, isTrue);
    });

    test('LoginFormValid requires both valid email and 6+ char password', () {
      expect(controller.isLoginFormValid.value, isFalse);

      controller.emailCtrl.text = 'user@example.com';
      expect(controller.isLoginFormValid.value, isFalse);

      controller.passwordCtrl.text = 'abc';
      expect(controller.isLoginFormValid.value, isFalse);

      controller.passwordCtrl.text = 'secret1';
      expect(controller.isLoginFormValid.value, isTrue);

      // Breaking email breaks form
      controller.emailCtrl.text = 'invalid-email';
      expect(controller.isLoginFormValid.value, isFalse);
    });

    test('SignupFormValid requires valid email, password, and matching confirm', () {
      controller.emailCtrl.text = 'user@example.com';
      controller.passwordCtrl.text = 'pass123';
      controller.confirmPasswordCtrl.text = 'pass123';

      expect(controller.isSignupFormValid.value, isTrue);

      // Mismatch
      controller.confirmPasswordCtrl.text = 'pass1234';
      expect(controller.isSignupFormValid.value, isFalse);
    });

    test('Typing in fields immediately clears stale server error banner', () {
      controller.errorMessage.value = 'Incorrect email or password. Please try again.';
      expect(controller.errorMessage.value, isNotEmpty);

      // User types a single letter in password
      controller.passwordCtrl.text = 'a';
      expect(controller.errorMessage.value, isEmpty);

      // Set error again
      controller.errorMessage.value = 'No account found with this email address.';
      controller.emailCtrl.text = 'new@mail.com';
      expect(controller.errorMessage.value, isEmpty);
    });
  });

  group('Real-Time UI Widget Tests', () {
    testWidgets('LoginView displays real-time email valid checkmark when email is valid', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const GetMaterialApp(
            home: LoginView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially no check_circle_rounded icon
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // Enter valid email
      final emailFinder = find.widgetWithText(TextFormField, 'you@example.com');
      await tester.enterText(emailFinder, 'creator@craftai.studio');
      await tester.pumpAndSettle();

      // Real-time checkmark is now visible!
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Enter invalid email
      await tester.enterText(emailFinder, 'not-an-email');
      await tester.pumpAndSettle();

      // Checkmark disappears in real time!
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('SignupView displays real-time password requirement and match indicators', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const GetMaterialApp(
            home: SignupView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "At least 6 characters" row is visible
      expect(find.text('At least 6 characters'), findsOneWidget);

      // Enter 4 characters
      final passwordFinder = find.widgetWithText(TextFormField, '6+ characters');
      await tester.enterText(passwordFinder, 'abcd');
      await tester.pumpAndSettle();

      // Less than 6 characters -> not yet valid
      expect(controller.isPasswordValid.value, isFalse);

      // Enter 6 characters
      await tester.enterText(passwordFinder, 'abcdef');
      await tester.pumpAndSettle();

      expect(controller.isPasswordValid.value, isTrue);

      // Now test confirm password match
      final confirmFinder = find.widgetWithText(TextFormField, 'Re-enter password');
      await tester.ensureVisible(confirmFinder);
      await tester.enterText(confirmFinder, 'different');
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);

      // Make confirm match
      await tester.enterText(confirmFinder, 'abcdef');
      await tester.pumpAndSettle();

      expect(controller.isConfirmPasswordValid.value, isTrue);
      expect(find.text('Passwords match'), findsOneWidget);
    });
  });
}
