import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/routes/app_routes.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/views/login_view.dart';
import '../../mocks/mock_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;

  Widget buildTestableLogin() {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => GetMaterialApp(
        home: const LoginView(),
        getPages: [
          GetPage(name: AppRoutes.home, page: () => const Scaffold(body: Text('Home'))),
        ],
      ),
    );
  }

  setUp(() {
    Get.reset();
    Get.testMode = true;
    mockRepo = MockAuthRepository();
    Get.put(AuthController(repository: mockRepo));
  });

  tearDown(() {
    mockRepo.dispose();
    Get.reset();
  });

  group('Independent Login Form Validation Tests', () {
    testWidgets('Entering or modifying Email does NOT trigger Password validation error', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableLogin());
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextFormField, 'you@example.com');

      // 1. Initially, no error text on either field
      expect(find.text('Password is required'), findsNothing);
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Enter a valid email address'), findsNothing);

      // 2. Type an invalid email in Email field
      await tester.enterText(emailField, 'incomplete-email');
      await tester.pumpAndSettle();

      // Email field shows its own validation error
      expect(find.text('Enter a valid email address'), findsOneWidget);

      // Password field must NOT have validation triggered
      expect(find.text('Password is required'), findsNothing);
      expect(find.text('Password must be at least 6 characters'), findsNothing);

      // 3. Complete valid email in Email field
      await tester.enterText(emailField, 'valid@example.com');
      await tester.pumpAndSettle();

      // Email error is cleared, checkmark shown
      expect(find.text('Enter a valid email address'), findsNothing);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Password field STILL has no error
      expect(find.text('Password is required'), findsNothing);
    });

    testWidgets('Entering or modifying Password does NOT trigger Email validation error', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableLogin());
      await tester.pumpAndSettle();

      final passwordField = find.widgetWithText(TextFormField, '••••••••');

      // 1. Initially clean
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsNothing);

      // 2. Type short password in Password field
      await tester.enterText(passwordField, '123');
      await tester.pumpAndSettle();

      // Password field shows its own validation error
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      // Email field must NOT have validation triggered
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Enter a valid email address'), findsNothing);

      // 3. Clear password in Password field
      await tester.enterText(passwordField, '');
      await tester.pumpAndSettle();

      // Password field shows required error
      expect(find.text('Password is required'), findsOneWidget);

      // Email field STILL has no error
      expect(find.text('Email is required'), findsNothing);
    });

    testWidgets('Form submission validates both fields independently and displays respective errors', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestableLogin());
      await tester.pumpAndSettle();

      final submitBtn = find.text('Sign In');

      // 1. Submit empty form
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Both fields display their respective errors
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
      expect(mockRepo.signInCalls, 0);

      // 2. User types in Email field -> Email error updates independently while Password error remains
      final emailField = find.widgetWithText(TextFormField, 'you@example.com');
      await tester.enterText(emailField, 'user@example.com');
      await tester.pumpAndSettle();

      // Email error is cleared, but Password error is still displayed
      expect(find.text('Email is required'), findsNothing);
      expect(find.text('Password is required'), findsOneWidget);

      // 3. User types in Password field -> Password error updates independently
      final passwordField = find.widgetWithText(TextFormField, '••••••••');
      await tester.enterText(passwordField, '123');
      await tester.pumpAndSettle();

      // Password error changes to length requirement, Email is untouched
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      expect(find.text('Email is required'), findsNothing);

      // 4. User completes valid password
      await tester.enterText(passwordField, 'secret123');
      await tester.pumpAndSettle();

      // Both errors cleared
      expect(find.text('Password must be at least 6 characters'), findsNothing);
      expect(find.text('Password is required'), findsNothing);
      expect(find.text('Email is required'), findsNothing);

      // 5. Submit valid form
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(mockRepo.signInCalls, 1);
      expect(mockRepo.lastSignInEmail, 'user@example.com');
      expect(mockRepo.lastSignInPassword, 'secret123');
    });
  });
}
