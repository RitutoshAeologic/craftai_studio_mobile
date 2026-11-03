import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/shell/views/home_shell_view.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/creation_studio_view.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/library/views/cloud_library_view.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/collection_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/auth/data/auth_repository.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import '../../mocks/fake_studio_repository.dart';

class _MockAuthRepository extends AuthRepository {
  @override
  AuthUserModel? get currentUser => const AuthUserModel(
        id: '12345678-abcd-ef01-2345-6789abcdef01',
        email: 'creator@craftai.studio',
        displayName: 'Craft Creator',
        emailConfirmedAt: null,
      );

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> signOut() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Studio UI Updates Tests', () {
    late StudioController studioController;

    setUp(() {
      Get.reset();
      Get.put(ShellController());
      Get.put(LibraryController());
      studioController = Get.put(StudioController(repository: FakeStudioRepository()));
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Aspect ratio dropdown and Polish button are adjacent, and Photo capsule is on extreme right', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: CreationStudioView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Polish button is present
      expect(find.text('Polish ✨'), findsOneWidget);

      // 2. Verify Aspect Ratio dropdown is present adjacent to Polish button
      expect(find.byType(DropdownButton<String>), findsOneWidget);
      expect(find.text('1:1'), findsOneWidget);

      // 3. Verify Photo capsule (+ Photo) is present on the right
      expect(find.text('+ Photo'), findsOneWidget);

      // 4. Verify separate sections are removed from the view
      // "Add Image Reference (Face Lock / Style)" should NOT be present
      expect(find.text('Add Image Reference (Face Lock / Style)'), findsNothing);
      // Standalone "Aspect Ratio & Frame" header should NOT be present
      expect(find.text('Aspect Ratio & Frame'), findsNothing);
    });

    testWidgets('Changing Aspect Ratio dropdown updates controller.selectedAspectRatio', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: CreationStudioView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(studioController.selectedAspectRatio.value, equals('1:1'));

      // Tap dropdown to open items
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Tap Story (9:16)
      await tester.tap(find.text('Story (9:16)').last);
      await tester.pumpAndSettle();

      expect(studioController.selectedAspectRatio.value, equals('9:16'));
    });
  });

  group('Device Back Navigation & Generation Lock Tests', () {
    late ShellController shellController;
    late StudioController studioController;

    setUp(() {
      Get.reset();
      Get.put(AuthController(repository: _MockAuthRepository()));
      shellController = Get.put(ShellController());
      Get.put(LibraryController());
      Get.put(CollectionController());
      Get.put(ExploreController());
      studioController = Get.put(StudioController(repository: FakeStudioRepository()));
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Back button when on Studio (tab 1) navigates to Explore (tab 0)', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: HomeShellView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Studio tab (index 1)
      shellController.switchTab(1);
      await tester.pump();
      expect(shellController.currentIndex.value, equals(1));

      // Simulate device back button press via root PopScope onPopInvokedWithResult
      final dynamic popScopeWidget = tester.widget(find.byType(PopScope).first);
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump();

      // Navigated to Explore (tab 0)
      expect(shellController.currentIndex.value, equals(0));
    });

    testWidgets('Back button when on Library (tab 3) navigates to Explore (tab 0)', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: HomeShellView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Library tab (index 3)
      shellController.switchTab(3);
      await tester.pump();
      expect(shellController.currentIndex.value, equals(3));

      // Simulate device back button press
      final dynamic popScopeWidget = tester.widget(find.byType(PopScope).first);
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Navigated to Explore (tab 0)
      expect(shellController.currentIndex.value, equals(0));
    });

    testWidgets('Back button during image generation displays warning dialog and blocks navigation', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: HomeShellView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to Studio (index 1) and simulate active image generation
      shellController.switchTab(1);
      studioController.isGenerating.value = true;
      await tester.pump();

      // Simulate device back button press
      final dynamic popScopeWidget = tester.widget(find.byType(PopScope).first);
      popScopeWidget.onPopInvokedWithResult(false, null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Navigation is blocked: still on Studio tab (index 1)
      expect(shellController.currentIndex.value, equals(1));

      // 2. Warning dialog is displayed
      expect(find.text('Generation in Progress'), findsOneWidget);
      expect(find.text('Understood'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('Understood'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      studioController.isGenerating.value = false;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Generation in Progress'), findsNothing);
    });
  });

  group('Library Two Tabs (Current & Collections) Tests', () {
    setUp(() {
      Get.reset();
      Get.put(ShellController());
      Get.put(LibraryController());
      Get.put(CollectionController());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('CloudLibraryView renders Current and Collections tabs', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: CloudLibraryView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify both tabs are visible in the TabBar
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Collections'), findsOneWidget);

      // 2. Tap Collections tab
      await tester.tap(find.text('Collections'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 3. Verify Collections view shows collection items
      expect(find.text('New Collection'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Cyberpunk & Sci-Fi'), findsOneWidget);
      expect(find.text('Character References'), findsOneWidget);
    });
  });
}
