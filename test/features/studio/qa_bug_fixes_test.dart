import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/theme/theme_controller.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/auth/domain/auth_user_model.dart';
import 'package:craftai_studio_mobile/features/auth/presentation/controllers/auth_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/profile/views/profile_view.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/shell/views/home_shell_view.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/ai_model_item.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/creation_studio_view.dart';
import '../../mocks/fake_studio_repository.dart';
import '../../mocks/mock_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QA Bug Fixes Verification (MOB-BUG-02 to MOB-BUG-05)', () {
    setUp(() {
      Get.reset();
      GoogleFonts.config.allowRuntimeFetching = false;
      SharedPreferences.setMockInitialValues({});
      AppColors.applyPreset(AppThemePreset.luminousAurora);
    });

    tearDown(() {
      AppColors.applyPreset(AppThemePreset.luminousAurora);
      Get.reset();
    });

    testWidgets('MOB-BUG-02: ProfileView Active badge moves to the selected theme preset', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAuth = MockAuthRepository()
        ..mockCurrentUser = const AuthUserModel(
          id: '12345678-abcd-ef01-2345-6789abcdef01',
          email: 'creator@craftai.studio',
          displayName: 'Craft Creator',
        );
      final authCtrl = Get.put(AuthController(repository: mockAuth), permanent: true);
      authCtrl.currentUser.value = mockAuth.mockCurrentUser;

      final themeCtrl = Get.put(ThemeController());
      Get.put(ShellController());

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const GetMaterialApp(home: ProfileView()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially Luminous Aurora has the single Active badge
      expect(find.text('Active'), findsOneWidget);

      // Switch to Deep Obsidian Dark
      themeCtrl.switchTheme(AppThemePreset.deepObsidian);
      await tester.pumpAndSettle();

      expect(themeCtrl.currentPreset.value, AppThemePreset.deepObsidian);
      expect(find.text('Active'), findsOneWidget);

      // Verify the 'Active' badge is inside the Deep Obsidian Dark row, not Luminous Aurora
      final deepObsidianText = find.text('Deep Obsidian Dark');
      final auroraText = find.text('Luminous Aurora');
      final activeBadge = find.text('Active');
      final activeY = tester.getCenter(activeBadge).dy;
      final obsidianY = tester.getCenter(deepObsidianText).dy;
      final auroraY = tester.getCenter(auroraText).dy;

      expect((activeY - obsidianY).abs(), lessThan((activeY - auroraY).abs()));
    });

    test('MOB-BUG-03: ThemeController persists theme across restarts via SharedPreferences', () async {
      final ctrl1 = Get.put(ThemeController());
      ctrl1.switchTheme(AppThemePreset.warmCashmere);
      await Future.delayed(const Duration(milliseconds: 50));

      // Simulate cold restart with fresh ThemeController
      Get.reset();
      AppColors.applyPreset(AppThemePreset.luminousAurora);
      final ctrl2 = Get.put(ThemeController());
      await ctrl2.loadSavedTheme();

      expect(ctrl2.currentPreset.value, AppThemePreset.warmCashmere);
      expect(AppColors.currentPreset, AppThemePreset.warmCashmere);
    });

    testWidgets('MOB-BUG-04: HomeShellView preserves IndexedStack tab state across theme switch',
        (tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockAuth = MockAuthRepository()
        ..mockCurrentUser = const AuthUserModel(
          id: '12345678-abcd-ef01-2345-6789abcdef01',
          email: 'creator@craftai.studio',
          displayName: 'Craft Creator',
        );
      final authCtrl = Get.put(AuthController(repository: mockAuth), permanent: true);
      authCtrl.currentUser.value = mockAuth.mockCurrentUser;

      final themeCtrl = Get.put(ThemeController());
      final shellCtrl = Get.put(ShellController());
      shellCtrl.userCredits.value = 100.0;
      Get.put(LibraryController());
      final studioCtrl = Get.put(StudioController(repository: FakeStudioRepository()));

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const GetMaterialApp(home: HomeShellView()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      shellCtrl.switchTab(1);
      await tester.pump();

      final studioElementBefore = tester.element(find.byType(CreationStudioView, skipOffstage: false));
      studioCtrl.promptController.text = 'Preserved neon city prompt';

      themeCtrl.switchTheme(AppThemePreset.deepObsidian);
      await tester.pump();

      final studioElementAfter = tester.element(find.byType(CreationStudioView, skipOffstage: false));
      expect(identical(studioElementBefore, studioElementAfter), isTrue);
      expect(studioCtrl.promptController.text, 'Preserved neon city prompt');
    });

    test('MOB-BUG-05: startTemplateRemixGeneration falls back to auto when paid models are unavailable',
        () async {
      final shellCtrl = Get.put(ShellController());
      shellCtrl.userCredits.value = 100.0;
      Get.put(LibraryController());
      final studioCtrl = Get.put(StudioController(repository: FakeStudioRepository()));

      final geminiTemplate = ExploreCardModel(
        id: 't_gemini',
        authorName: 'A',
        authorHandle: '@a',
        authorAvatar: '',
        title: 'Gemini Style',
        previewUrl: '',
        category: 'Art',
        modelUsed: 'Google Gemini',
        aspectRatio: '1:1',
        fullPrompt: 'Artistic portrait',
        maskedSummary: 'Artistic portrait',
        remixFee: 4.0,
        creatorRoyaltyCut: 1.6,
        remixCount: 10,
        likeCount: 50,
      );

      await studioCtrl.startTemplateRemixGeneration(
        template: geminiTemplate,
        userPhoto: File('/tmp/non_existent_test.jpg'),
      );
      expect(studioCtrl.selectedModel.value, 'auto');

      // When flux_pulid_facelock IS available in catalog, Flux template selects it
      studioCtrl.catalogModels.add(
        const AiModelItem(
          modelKey: 'flux_pulid_facelock',
          displayName: 'FLUX PuLID Face-Lock',
          providerKey: 'fal',
          tasks: ['face_lock_remix'],
          tier: 'premium',
          creditCost: 4.0,
          isAvailable: true,
          activeMode: 'paid_api',
        ),
      );

      final fluxTemplate = ExploreCardModel(
        id: 't_flux',
        authorName: 'B',
        authorHandle: '@b',
        authorAvatar: '',
        title: 'Flux Style',
        previewUrl: '',
        category: 'Cyberpunk',
        modelUsed: 'FLUX.1 Schnell',
        aspectRatio: '9:16',
        fullPrompt: 'Neon portrait',
        maskedSummary: 'Neon portrait',
        remixFee: 4.0,
        creatorRoyaltyCut: 1.6,
        remixCount: 10,
        likeCount: 50,
      );

      await studioCtrl.startTemplateRemixGeneration(
        template: fluxTemplate,
        userPhoto: File('/tmp/non_existent_test.jpg'),
      );
      expect(studioCtrl.selectedModel.value, 'flux_pulid_facelock');
    });
  });
}
