import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/core/services/network_service.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_failure.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../../mocks/mock_auth_repository.dart';

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

  group('1. Email Format Validation Matrix & Edge Cases', () {
    test('Empty and whitespace-only email values are rejected', () {
      expect(AuthController.isValidEmail(null), isFalse);
      expect(AuthController.isValidEmail(''), isFalse);
      expect(AuthController.isValidEmail('   '), isFalse);
      expect(AuthController.isValidEmail('\t\n\r'), isFalse);

      expect(AuthController.validateEmail(null), 'Email is required');
      expect(AuthController.validateEmail(''), 'Email is required');
      expect(AuthController.validateEmail('   '), 'Email is required');
    });

    test('Malformed email patterns are cleanly rejected', () {
      const invalidEmails = [
        'plainaddress',
        '#@%^%#\$@#\$@#.com',
        '@example.com',
        'Joe Smith <email@example.com>',
        'email.example.com',
        'email@example@example.com',
        '.email@example.com',
        'email.@example.com',
        'email..email@example.com',
        'email@example',
        'email@example.c', // TLD < 2 chars
        'user@.com',
        'user@domain..com',
        'user😊@example.com', // emoji in local part
      ];

      for (final email in invalidEmails) {
        expect(
          AuthController.isValidEmail(email),
          isFalse,
          reason: 'Expected "$email" to be invalid',
        );
        expect(
          AuthController.validateEmail(email),
          'Enter a valid email address',
          reason: 'Expected "$email" to return invalid format message',
        );
      }
    });

    test('Valid and complex RFC-compliant emails are accepted', () {
      const validEmails = [
        'email@example.com',
        'firstname.lastname@example.com',
        'email@subdomain.example.com',
        'firstname+lastname@example.com',
        'email@123.123.123.com',
        '1234567890@example.com',
        'email@example-one.com',
        '_______@example.com',
        'email@example.name',
        'email@example.museum',
        'email@example.co.uk',
        '  email@example.com  ', // leading/trailing whitespace
      ];

      for (final email in validEmails) {
        expect(
          AuthController.isValidEmail(email),
          isTrue,
          reason: 'Expected "$email" to be valid',
        );
        expect(
          AuthController.validateEmail(email),
          isNull,
          reason: 'Expected "$email" to return null validator error',
        );
      }
    });
  });

  group('2. Password Length & Boundary Edge Cases', () {
    test('Empty password triggers required error', () {
      expect(AuthController.isValidPassword(null), isFalse);
      expect(AuthController.isValidPassword(''), isFalse);
      expect(AuthController.validatePassword(null), 'Password is required');
      expect(AuthController.validatePassword(''), 'Password is required');
    });

    test('Sub-boundary passwords (< 6 characters) are rejected', () {
      const shortPasswords = ['a', 'ab', 'abc', '1234', '12345'];
      for (final pwd in shortPasswords) {
        expect(AuthController.isValidPassword(pwd), isFalse);
        expect(
          AuthController.validatePassword(pwd),
          'Password must be at least 6 characters',
        );
      }
    });

    test('Boundary (exactly 6 characters) and longer passwords are accepted', () {
      expect(AuthController.isValidPassword('123456'), isTrue);
      expect(AuthController.validatePassword('123456'), isNull);

      expect(AuthController.isValidPassword('1234567'), isTrue);
      expect(AuthController.validatePassword('1234567'), isNull);

      const complexLong = 'Super#Secure_P@ssw0rd!2026-CraftAI';
      expect(AuthController.isValidPassword(complexLong), isTrue);
      expect(AuthController.validatePassword(complexLong), isNull);
    });
  });

  group('3. Confirm Password Match Edge Cases', () {
    test('Empty confirm password triggers please confirm error', () {
      expect(AuthController.isValidConfirm(null, 'secret123'), isFalse);
      expect(AuthController.isValidConfirm('', 'secret123'), isFalse);
      expect(AuthController.validateConfirm(null, 'secret123'), 'Please confirm your password');
      expect(AuthController.validateConfirm('', 'secret123'), 'Please confirm your password');
    });

    test('Mismatched confirm password triggers mismatch error', () {
      expect(AuthController.isValidConfirm('secret12', 'secret123'), isFalse);
      expect(AuthController.validateConfirm('secret12', 'secret123'), 'Passwords do not match');
    });

    test('Case sensitivity and trailing whitespace mismatches are respected', () {
      expect(AuthController.isValidConfirm('Password123', 'password123'), isFalse);
      expect(AuthController.validateConfirm('Password123', 'password123'), 'Passwords do not match');

      expect(AuthController.isValidConfirm('password123 ', 'password123'), isFalse);
      expect(AuthController.validateConfirm('password123 ', 'password123'), 'Passwords do not match');
    });

    test('Identical confirm password returns valid (null)', () {
      expect(AuthController.isValidConfirm('MyP@ssword123', 'MyP@ssword123'), isTrue);
      expect(AuthController.validateConfirm('MyP@ssword123', 'MyP@ssword123'), isNull);
    });
  });

  group('4. Form-Level Combinatorial Validations & Keystroke Sync', () {
    test('Initial controller state has all valid flags as false', () {
      expect(controller.isEmailValid.value, isFalse);
      expect(controller.isPasswordValid.value, isFalse);
      expect(controller.isConfirmPasswordValid.value, isFalse);
      expect(controller.isLoginFormValid.value, isFalse);
      expect(controller.isSignupFormValid.value, isFalse);
      expect(controller.isForgotFormValid.value, isFalse);
    });

    test('Combinations of email and password update isLoginFormValid correctly', () {
      // 1. Email invalid, Password invalid -> false
      controller.emailCtrl.text = 'bad-email';
      controller.passwordCtrl.text = '123';
      expect(controller.isLoginFormValid.value, isFalse);

      // 2. Email valid, Password invalid -> false
      controller.emailCtrl.text = 'good@craftai.studio';
      expect(controller.isLoginFormValid.value, isFalse);

      // 3. Email valid, Password valid -> true
      controller.passwordCtrl.text = 'securePass1';
      expect(controller.isLoginFormValid.value, isTrue);

      // 4. Invalidate email -> false
      controller.emailCtrl.text = 'good@craftai.';
      expect(controller.isLoginFormValid.value, isFalse);
    });

    test('SignupFormValid requires all 3 fields and synchronizes dynamically', () {
      controller.emailCtrl.text = 'alice@example.com';
      controller.passwordCtrl.text = 'wonderland99';
      controller.confirmPasswordCtrl.text = 'wonderland99';

      expect(controller.isSignupFormValid.value, isTrue);

      // Modifying password breaks confirm match immediately
      controller.passwordCtrl.text = 'wonderland100';
      expect(controller.isConfirmPasswordValid.value, isFalse);
      expect(controller.isSignupFormValid.value, isFalse);

      // Re-align confirm
      controller.confirmPasswordCtrl.text = 'wonderland100';
      expect(controller.isConfirmPasswordValid.value, isTrue);
      expect(controller.isSignupFormValid.value, isTrue);
    });

    test('ForgotFormValid only requires a valid email', () {
      expect(controller.isForgotFormValid.value, isFalse);

      controller.emailCtrl.text = 'user@example.com';
      expect(controller.isForgotFormValid.value, isTrue);

      controller.emailCtrl.text = '';
      expect(controller.isForgotFormValid.value, isFalse);
    });
  });

  group('5. UI State Management, Toggles & Field Reset', () {
    test('Visibility toggles flip boolean observables', () {
      expect(controller.isPasswordVisible.value, isFalse);
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible.value, isTrue);
      controller.togglePasswordVisibility();
      expect(controller.isPasswordVisible.value, isFalse);

      expect(controller.isConfirmPasswordVisible.value, isFalse);
      controller.toggleConfirmPasswordVisibility();
      expect(controller.isConfirmPasswordVisible.value, isTrue);
      controller.toggleConfirmPasswordVisibility();
      expect(controller.isConfirmPasswordVisible.value, isFalse);
    });

    test('Typing in any input field clears stale error banner immediately', () {
      controller.errorMessage.value = 'Invalid credentials';
      expect(controller.errorMessage.value, isNotEmpty);

      controller.displayNameCtrl.text = 'Bob';
      expect(controller.errorMessage.value, isEmpty);

      controller.errorMessage.value = 'Network error';
      controller.emailCtrl.text = 'bob@craftai.com';
      expect(controller.errorMessage.value, isEmpty);

      controller.errorMessage.value = 'User not found';
      controller.passwordCtrl.text = 'newPass123';
      expect(controller.errorMessage.value, isEmpty);

      controller.errorMessage.value = 'Email already in use';
      controller.confirmPasswordCtrl.text = 'newPass123';
      expect(controller.errorMessage.value, isEmpty);
    });

    test('clearError resets errorMessage explicitly', () {
      controller.errorMessage.value = 'Some error';
      controller.clearError();
      expect(controller.errorMessage.value, isEmpty);
    });
  });

  group('6. Network Offline Pre-Flight Guard Tests', () {
    test('Sign in is blocked pre-flight when device is offline without calling repo', () async {
      final netSvc = NetworkService();
      netSvc.isConnected.value = false;
      Get.put<NetworkService>(netSvc, permanent: true);

      controller.emailCtrl.text = 'tester@example.com';
      controller.passwordCtrl.text = 'validpassword123';

      await controller.signIn();

      expect(mockRepo.signInCalls, 0);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, contains('No internet connection'));
    });

    test('Sign up is blocked pre-flight when device is offline without calling repo', () async {
      final netSvc = NetworkService();
      netSvc.isConnected.value = false;
      Get.put<NetworkService>(netSvc, permanent: true);

      controller.emailCtrl.text = 'tester@example.com';
      controller.passwordCtrl.text = 'validpassword123';
      controller.confirmPasswordCtrl.text = 'validpassword123';

      await controller.signUp();

      expect(mockRepo.signUpCalls, 0);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, contains('No internet connection'));
    });

    test('Password reset is blocked pre-flight when device is offline without calling repo', () async {
      final netSvc = NetworkService();
      netSvc.isConnected.value = false;
      Get.put<NetworkService>(netSvc, permanent: true);

      controller.emailCtrl.text = 'tester@example.com';

      await controller.sendPasswordReset();

      expect(mockRepo.resetPasswordCalls, 0);
      expect(controller.isLoading.value, isFalse);
      expect(controller.errorMessage.value, contains('No internet connection'));
    });
  });

  group('7. Auth Failure User-Facing Message Mappings', () {
    test('All AuthFailure subtypes are mapped to plain English without HTTP codes', () async {
      controller.emailCtrl.text = 'test@example.com';
      controller.passwordCtrl.text = 'password123';

      // 1. InvalidCredentials
      mockRepo.signInResult = (user: null, failure: const InvalidCredentials());
      await controller.signIn();
      expect(controller.errorMessage.value, 'Incorrect email or password. Please try again.');

      // 2. EmailAlreadyInUse
      controller.confirmPasswordCtrl.text = 'password123';
      mockRepo.signUpResult = (user: null, emailConfirmationRequired: false, failure: const EmailAlreadyInUse());
      await controller.signUp();
      expect(controller.errorMessage.value, 'This email is already registered. Try signing in instead.');

      // 3. WeakPassword
      mockRepo.signUpResult = (user: null, emailConfirmationRequired: false, failure: const WeakPassword());
      await controller.signUp();
      expect(controller.errorMessage.value, 'Password must be at least 6 characters.');

      // 4. EmailNotConfirmed
      mockRepo.signInResult = (user: null, failure: const EmailNotConfirmed());
      await controller.signIn();
      expect(controller.errorMessage.value, 'Please confirm your email address before signing in.');

      // 5. UserNotFound
      mockRepo.signInResult = (user: null, failure: const UserNotFound());
      await controller.signIn();
      expect(controller.errorMessage.value, 'No account found with this email address.');

      // 6. NetworkFailure
      mockRepo.signInResult = (user: null, failure: const NetworkFailure());
      await controller.signIn();
      expect(controller.errorMessage.value, 'Connection error. Check your internet and try again.');

      // 7. UnknownFailure
      mockRepo.signInResult = (user: null, failure: const UnknownFailure('Custom server failure'));
      await controller.signIn();
      expect(controller.errorMessage.value, 'Custom server failure');
    });
  });

  group('8. Auth State Stream & Session Transitions', () {
    test('Controller updates currentUser on authStateChanges events', () {
      expect(controller.currentUser.value, isNull);
      expect(controller.isAuthenticated, isFalse);

      // Emit signedIn
      const user = AuthUserModel(id: 'usr_abc', email: 'alice@example.com');
      mockRepo.mockCurrentUser = user;
      mockRepo.emitAuthState(AuthState(AuthChangeEvent.signedIn, null));

      expect(controller.currentUser.value, equals(user));
      expect(controller.isAuthenticated, isTrue);

      // Emit signedOut
      mockRepo.mockCurrentUser = null;
      mockRepo.emitAuthState(AuthState(AuthChangeEvent.signedOut, null));

      expect(controller.currentUser.value, isNull);
      expect(controller.isAuthenticated, isFalse);
    });
  });
}
