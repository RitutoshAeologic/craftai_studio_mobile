import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/routes/app_routes.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/views/forgot_password_view.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/views/login_view.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/views/signup_view.dart';
import '../../mocks/mock_auth_repository.dart';

Widget _buildTestApp(Widget home) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    builder: (_, __) => GetMaterialApp(
      key: UniqueKey(),
      home: home,
      getPages: [
        GetPage(name: AppRoutes.login, page: () => const LoginView()),
        GetPage(name: AppRoutes.signup, page: () => const SignupView()),
        GetPage(name: AppRoutes.forgotPassword, page: () => const ForgotPasswordView()),
        GetPage(name: AppRoutes.home, page: () => const Scaffold(body: Text('Home Screen'))),
      ],
    ),
  );
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

  void configureViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN VIEW USE CASES
  // ═══════════════════════════════════════════════════════════════════════════
  group('LoginView Use Cases & Real-Time Validation', () {
    testWidgets('Use Case L1: Initial layout renders all required elements', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'you@example.com'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '••••••••'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.textContaining('Don\'t have an account?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Use Case L2: Real-time email checkmark appears on valid format and vanishes on invalid', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'you@example.com');
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // Typing incomplete email
      await tester.enterText(emailField, 'dev@studio');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // Typing valid email
      await tester.enterText(emailField, 'dev@studio.ai');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Breaking email
      await tester.enterText(emailField, 'dev@studio.');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
    });

    testWidgets('Use Case L3: Password obscureText toggles when eye icon is tapped', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      final passwordFieldFinder = find.widgetWithText(TextFormField, '••••••••');
      final initialField = tester.widget<TextField>(
        find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
      );
      expect(initialField.obscureText, isTrue);

      // Tap visibility toggle icon
      final eyeIconFinder = find.byIcon(Icons.visibility_outlined);
      expect(eyeIconFinder, findsOneWidget);
      await tester.tap(eyeIconFinder);
      await tester.pumpAndSettle();

      // Now visible
      final visibleField = tester.widget<TextField>(
        find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
      );
      expect(visibleField.obscureText, isFalse);
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);

      // Tap again to obscure
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pumpAndSettle();
      final obscuredAgain = tester.widget<TextField>(
        find.descendant(of: passwordFieldFinder, matching: find.byType(TextField)),
      );
      expect(obscuredAgain.obscureText, isTrue);
    });

    testWidgets('Use Case L4: Submitting valid form triggers signInWithEmail with credentials', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'you@example.com');
      final passwordField = find.widgetWithText(TextFormField, '••••••••');
      final submitButton = find.text('Sign In');

      await tester.enterText(emailField, 'user@example.com');
      await tester.enterText(passwordField, 'mypassword123');
      await tester.pumpAndSettle();

      expect(controller.isLoginFormValid.value, isTrue);

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(mockRepo.signInCalls, 1);
      expect(mockRepo.lastSignInEmail, 'user@example.com');
      expect(mockRepo.lastSignInPassword, 'mypassword123');
    });

    testWidgets('Use Case L5: Typing in fields dismisses server error banner immediately', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const LoginView()));
      await tester.pumpAndSettle();

      controller.errorMessage.value = 'Incorrect email or password. Please try again.';
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password. Please try again.'), findsOneWidget);

      // Typing single character in email field clears banner
      final emailField = find.widgetWithText(TextFormField, 'you@example.com');
      await tester.enterText(emailField, 'a');
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password. Please try again.'), findsNothing);
      expect(controller.errorMessage.value, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SIGNUP VIEW USE CASES
  // ═══════════════════════════════════════════════════════════════════════════
  group('SignupView Use Cases & Real-Time Validation', () {
    testWidgets('Use Case S1: Initial layout renders all input fields and indicators', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const SignupView()));
      await tester.pumpAndSettle();

      expect(find.text('Create Account'), findsWidgets);
      expect(find.widgetWithText(TextFormField, 'Your creator name'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'you@example.com'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '6+ characters'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Re-enter password'), findsOneWidget);
      expect(find.text('At least 6 characters'), findsOneWidget);
      expect(find.textContaining('Already have an account?'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('Use Case S2: Password length indicator updates dynamically on 6-character boundary', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const SignupView()));
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextFormField, '6+ characters');

      // Initial state: not valid
      expect(controller.isPasswordValid.value, isFalse);

      // 5 chars: invalid
      await tester.enterText(passwordField, '12345');
      await tester.pumpAndSettle();
      expect(controller.isPasswordValid.value, isFalse);

      // 6 chars: valid
      await tester.enterText(passwordField, '123456');
      await tester.pumpAndSettle();
      expect(controller.isPasswordValid.value, isTrue);

      // Backspace to 5 chars: invalid again
      await tester.enterText(passwordField, '12345');
      await tester.pumpAndSettle();
      expect(controller.isPasswordValid.value, isFalse);
    });

    testWidgets('Use Case S3: Confirm password displays mismatch and match indicators reactively', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const SignupView()));
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextFormField, '6+ characters');
      final confirmField = find.widgetWithText(TextFormField, 'Re-enter password');

      await tester.enterText(passwordField, 'masterkey');
      await tester.ensureVisible(confirmField);
      await tester.enterText(confirmField, 'differentkey');
      await tester.pumpAndSettle();

      // Mismatch
      expect(controller.isConfirmPasswordValid.value, isFalse);
      expect(find.text('Passwords do not match'), findsOneWidget);
      expect(find.text('Passwords match'), findsNothing);

      // Match
      await tester.enterText(confirmField, 'masterkey');
      await tester.pumpAndSettle();

      expect(controller.isConfirmPasswordValid.value, isTrue);
      expect(find.text('Passwords match'), findsOneWidget);
    });

    testWidgets('Use Case S4: Submitting complete form triggers signUpWithEmail with all parameters', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const SignupView()));
      await tester.pumpAndSettle();

      final nameField = find.widgetWithText(TextFormField, 'Your creator name');
      final emailField = find.widgetWithText(TextFormField, 'you@example.com');
      final passwordField = find.widgetWithText(TextFormField, '6+ characters');
      final confirmField = find.widgetWithText(TextFormField, 'Re-enter password');
      final submitButton = find.text('Create Account').last;

      await tester.enterText(nameField, 'Test User');
      await tester.enterText(emailField, 'test@example.com');
      await tester.enterText(passwordField, 'secret123');
      await tester.ensureVisible(confirmField);
      await tester.enterText(confirmField, 'secret123');
      await tester.pumpAndSettle();

      expect(controller.isSignupFormValid.value, isTrue);

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(mockRepo.signUpCalls, 1);
      expect(mockRepo.lastSignUpEmail, 'test@example.com');
      expect(mockRepo.lastSignUpPassword, 'secret123');
      expect(mockRepo.lastSignUpDisplayName, 'Test User');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD VIEW USE CASES
  // ═══════════════════════════════════════════════════════════════════════════
  group('ForgotPasswordView Use Cases & Real-Time Validation', () {
    testWidgets('Use Case F1: Initial layout renders header, email field, and action button', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const ForgotPasswordView()));
      await tester.pumpAndSettle();

      expect(find.text('Reset password'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'you@example.com'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('← Back to Sign In'), findsOneWidget);
    });

    testWidgets('Use Case F2: Real-time email validation checkmark in reset form', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const ForgotPasswordView()));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'you@example.com');
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      await tester.enterText(emailField, 'user@craftai.io');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(controller.isForgotFormValid.value, isTrue);

      await tester.enterText(emailField, 'incomplete@');
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);
      expect(controller.isForgotFormValid.value, isFalse);
    });

    testWidgets('Use Case F3: Submitting valid email triggers sendPasswordResetEmail', (tester) async {
      configureViewport(tester);
      await tester.pumpWidget(_buildTestApp(const ForgotPasswordView()));
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'you@example.com');
      final submitButton = find.text('Send Reset Link');

      await tester.enterText(emailField, 'forgot@example.com');
      await tester.pumpAndSettle();

      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(mockRepo.resetPasswordCalls, 1);
      expect(mockRepo.lastResetEmail, 'forgot@example.com');
    });
  });
}
