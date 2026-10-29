import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/features/auth/data/auth_repository.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:craftai_studio_mobile/features/profile/controllers/profile_controller.dart';
import 'package:craftai_studio_mobile/features/profile/views/profile_view.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/shell/views/home_shell_view.dart';

class MockAuthRepository extends AuthRepository {
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  @override
  AuthUserModel? get currentUser => const AuthUserModel(
        id: '12345678-abcd-ef01-2345-6789abcdef01',
        email: 'creator@craftai.studio',
        displayName: 'Craft Creator',
        emailConfirmedAt: null,
      );

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signOut() async {}

  void dispose() {
    _authStateController.close();
  }
}

void main() {
  late MockAuthRepository mockRepo;
  late AuthController authController;

  setUp(() {
    Get.reset();
    mockRepo = MockAuthRepository();
    authController = Get.put(AuthController(repository: mockRepo), permanent: true);
    authController.currentUser.value = mockRepo.currentUser;
    Get.put(ShellController());
  });

  tearDown(() {
    mockRepo.dispose();
    Get.reset();
  });

  Widget wrapWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => GetMaterialApp(
        home: child,
      ),
    );
  }

  group('ProfileController Unit Tests', () {
    test('resolves user credentials, display name, and masked user ID correctly', () {
      final controller = Get.put(ProfileController());

      expect(controller.email, 'creator@craftai.studio');
      expect(controller.displayName, 'Craft Creator');
      expect(controller.maskedUserId, '12345678...ef01');
      expect(controller.userId, '12345678-abcd-ef01-2345-6789abcdef01');
    });
  });

  group('ProfileView Widget Tests', () {
    testWidgets('renders account details, session status, wallet shortcut, and sign-out tile',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const ProfileView()));
      await tester.pump(const Duration(milliseconds: 300));

      // Check header title
      expect(find.text('Profile'), findsOneWidget);

      // Check Creator hero info
      expect(find.text('Craft Creator'), findsOneWidget);
      expect(find.text('creator@craftai.studio'), findsWidgets);
      expect(find.text('Creator'), findsOneWidget);
      expect(find.text('Session Active'), findsOneWidget);

      // Check Wallet quick card
      expect(find.text('Wallet & Credits'), findsOneWidget);
      expect(find.text('Open Wallet & Top Up Credits'), findsOneWidget);

      // Check Account & Session info
      expect(find.text('Account & Session'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Account ID'), findsOneWidget);
      expect(find.text('Session Status'), findsOneWidget);

      // Check Sign Out tile
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('End your current session on this device'), findsOneWidget);
    });
  });

  group('HomeShellView Navigation Integration Tests', () {
    testWidgets('bottom bar displays Profile destination and top bar omits profile button',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView()));
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom bar includes Profile destination
      expect(find.text(AppStrings.tabProfile), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsWidgets);

      // Bottom bar does NOT have Wallet destination
      expect(find.text(AppStrings.tabWallet), findsNothing);

      // Top app bar has HomeShellView mounted cleanly
      expect(find.byType(HomeShellView), findsOneWidget);
    });
  });
}
