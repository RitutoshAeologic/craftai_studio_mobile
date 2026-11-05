import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/theme/theme_controller.dart';
import 'package:craftai_studio_mobile/features/auth/data/auth_repository.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/shell/views/home_shell_view.dart';

class _TestMockAuthRepository extends AuthRepository {
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  @override
  AuthUserModel? get currentUser => const AuthUserModel(
        id: '12345678-abcd-ef01-2345-6789abcdef01',
        email: 'creator@craftai.studio',
        displayName: 'Craft Creator',
      );

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signOut() async {}

  void dispose() {
    _authStateController.close();
  }
}

Widget wrapWithScreenUtil(Widget child, {EdgeInsets padding = EdgeInsets.zero}) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (context, _) => MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        padding: padding,
        viewPadding: padding,
      ),
      child: GetMaterialApp(
        home: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _TestMockAuthRepository mockRepo;
  late AuthController authController;

  setUp(() {
    Get.reset();
    mockRepo = _TestMockAuthRepository();
    authController = Get.put(AuthController(repository: mockRepo), permanent: true);
    authController.currentUser.value = mockRepo.currentUser;
    Get.put(ShellController());
    Get.put(ThemeController());
  });

  tearDown(() {
    mockRepo.dispose();
    Get.reset();
  });

  group('HomeShellView Bottom Navigation Bar Layout Tests', () {
    testWidgets('pill height remains compact (<= 66px) and does not inherit top notch padding on iOS',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Simulate iPhone 14/15/16 with 47px top notch and 34px bottom home indicator
      const iOSPadding = EdgeInsets.only(top: 47.0, bottom: 34.0);

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView(), padding: iOSPadding));
      await tester.pump(const Duration(milliseconds: 300));

      // Find NavigationBar
      final navBarFinder = find.byType(NavigationBar);
      expect(navBarFinder, findsOneWidget);

      final navBarRenderBox = tester.renderObject<RenderBox>(navBarFinder);
      // NavigationBar height should be strictly around 62.h, NOT expanded to 62 + 47 = 109px
      expect(navBarRenderBox.size.height, lessThanOrEqualTo(66.0));
      expect(navBarRenderBox.size.height, greaterThanOrEqualTo(58.0));

      // Verify all 5 navigation destinations are present
      expect(find.text(AppStrings.tabExplore), findsOneWidget);
      expect(find.text(AppStrings.tabStudio), findsOneWidget);
      expect(find.text('AI Tools'), findsOneWidget);
      expect(find.text(AppStrings.tabLibrary), findsOneWidget);
      expect(find.text(AppStrings.tabProfile), findsOneWidget);
    });

    testWidgets('selected bottom tab destination has theme-matched translucent indicator and white icon',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView()));
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify NavigationBarTheme indicatorColor is theme-matched translucent
      final navBarTheme = tester.widget<NavigationBarTheme>(find.byType(NavigationBarTheme));
      final indicatorColor = navBarTheme.data.indicatorColor;
      expect(indicatorColor, isNotNull);
      expect(indicatorColor, equals(AppColors.primary.withValues(alpha: 0.82)));
      expect(indicatorColor!.a, closeTo(0.82, 0.01));

      // 2. Tab 0 (Explore) is selected by default -> verify selected icon in NavigationBar is white
      final exploreSelectedIcon = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == Icons.explore && widget.color == Colors.white,
        ),
      );
      expect(exploreSelectedIcon, findsOneWidget);

      // 3. Switch to Studio (Tab 1)
      final shellCtrl = Get.find<ShellController>();
      shellCtrl.switchTab(1);
      await tester.pump(const Duration(milliseconds: 300));

      final studioSelectedIcon = find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byWidgetPredicate(
          (widget) => widget is Icon && widget.icon == Icons.auto_awesome && widget.color == Colors.white,
        ),
      );
      expect(studioSelectedIcon, findsOneWidget);
    });
  });
}
