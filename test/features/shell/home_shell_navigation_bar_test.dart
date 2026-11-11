import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/core/theme/theme_controller.dart';
import 'package:craftai_studio_mobile/features/auth/data/auth_repository.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/creation_studio_view.dart';
import 'package:craftai_studio_mobile/features/tools/views/ai_tools_view.dart';
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
    testWidgets('bottom bar displays icon only for active tab and icon+label horizontally for inactive tab',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Simulate iPhone 14/15/16 with 47px top notch and 34px bottom home indicator
      const iOSPadding = EdgeInsets.only(top: 47.0, bottom: 34.0);

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView(), padding: iOSPadding));
      await tester.pump(const Duration(milliseconds: 300));

      final shellCtrl = Get.find<ShellController>();
      expect(shellCtrl.currentIndex.value, 0);

      // 1. Tab 0 (Explore) is active by default:
      // Active Explore shows only icon (white), label is hidden
      expect(find.byIcon(Icons.explore), findsOneWidget);
      expect(find.text(AppStrings.tabExplore), findsNothing);

      // Inactive Library displays both icon and label horizontally
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);
      expect(find.text(AppStrings.tabLibrary), findsOneWidget);

      // Verify removed destinations are NOT present in the bottom bar
      expect(find.text(AppStrings.tabStudio), findsNothing);
      expect(find.text('AI Tools'), findsNothing);
      expect(find.text(AppStrings.tabProfile), findsNothing);
    });

    testWidgets('switching tab toggles active icon-only state and expands inactive label smoothly',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView()));
      await tester.pump(const Duration(milliseconds: 300));

      final shellCtrl = Get.find<ShellController>();
      expect(shellCtrl.currentIndex.value, 0);

      // Switch to Library (Tab 3)
      shellCtrl.switchTab(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Active Library shows only icon (white), label is hidden
      expect(find.byIcon(Icons.folder), findsOneWidget);
      expect(find.text(AppStrings.tabLibrary), findsNothing);

      // Inactive Explore shows both icon and label horizontally
      expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
      expect(find.text(AppStrings.tabExplore), findsOneWidget);
    });

    testWidgets('ExpandableNavigationFab is located in bottom-right corner, expands upwards on tap, and collapses on re-tap',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView()));
      await tester.pump(const Duration(milliseconds: 300));

      final triggerFinder = find.byKey(const ValueKey('expandable_nav_fab_trigger'));
      expect(triggerFinder, findsOneWidget);

      // Verify FAB is located near the right edge of the screen (bottom-right)
      final fabRect = tester.getRect(triggerFinder);
      expect(fabRect.right, greaterThan(300.0));

      // Before tapping, menu items are not visible
      expect(find.text('Prompt to Image'), findsNothing);
      expect(find.text('AI Tools'), findsNothing);

      // Tap trigger to expand
      await tester.tap(triggerFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After expand, exactly two options are visible
      expect(find.text('Prompt to Image'), findsOneWidget);
      expect(find.text('AI Tools'), findsOneWidget);
      expect(find.text('Background Remover'), findsNothing);
      expect(find.text('AI Expand'), findsNothing);
      expect(find.text('Upscale 4K'), findsNothing);

      // Tap trigger again to collapse
      await tester.tap(triggerFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After collapse, menu is hidden
      expect(find.text('Prompt to Image'), findsNothing);
      expect(find.text('AI Tools'), findsNothing);
    });

    testWidgets('Tapping Library and Explore navigates between tabs correctly',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView()));
      await tester.pump(const Duration(milliseconds: 300));

      final shellCtrl = Get.find<ShellController>();
      expect(shellCtrl.currentIndex.value, 0);

      // Tap Library in bottom bar
      await tester.tap(find.text(AppStrings.tabLibrary));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(shellCtrl.currentIndex.value, 3);

      // Tap Explore in bottom bar
      await tester.tap(find.text(AppStrings.tabExplore));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(shellCtrl.currentIndex.value, 0);
    });

    testWidgets('Tapping Prompt to Image in FAB menu navigates to CreationStudioView cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView()));
      await tester.pump(const Duration(milliseconds: 300));

      // Open Expandable FAB
      final triggerFinder = find.byKey(const ValueKey('expandable_nav_fab_trigger'));
      await tester.tap(triggerFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Prompt to Image in expanded menu
      await tester.tap(find.text('Prompt to Image'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify CreationStudioView elements are rendered cleanly
      expect(find.byType(CreationStudioView), findsOneWidget);
      expect(find.text(AppStrings.studioTitle), findsOneWidget);
      expect(find.text('Surprise Me'), findsOneWidget);
    });

    testWidgets('Tapping AI Tools in FAB menu navigates to AiToolsView cleanly',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithScreenUtil(const HomeShellView()));
      await tester.pump(const Duration(milliseconds: 300));

      // Open Expandable FAB
      final triggerFinder = find.byKey(const ValueKey('expandable_nav_fab_trigger'));
      await tester.tap(triggerFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap AI Tools in expanded menu
      await tester.tap(find.text('AI Tools'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AiToolsView elements are rendered cleanly
      expect(find.byType(AiToolsView), findsOneWidget);
      expect(find.text('Creative Toolbox'), findsOneWidget);
    });
  });
}
