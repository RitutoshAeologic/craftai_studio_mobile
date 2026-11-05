import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/core/constants/app_colors.dart';
import 'package:craftai_studio_mobile/core/theme/theme_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/views/ai_tools_view.dart';
import '../studio/studio_responsiveness_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeController themeController;

  setUp(() {
    Get.reset();
    themeController = Get.put(ThemeController());
    Get.put<IStudioRepository>(MockStudioRepository());
    Get.put(ShellController());
    Get.put(StudioController(repository: Get.find<IStudioRepository>()));
    Get.put(ToolsController(repository: Get.find<IStudioRepository>()));
  });

  tearDown(() {
    Get.reset();
  });

  Widget wrapWithScreenUtil(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, __) => GetMaterialApp(
        home: child,
      ),
    );
  }

  group('AiToolsView Theme Preset Integration Tests', () {
    testWidgets('tool cards adapt to Deep Obsidian Dark theme without hardcoded white backgrounds',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Switch theme to Deep Obsidian
      themeController.switchTheme(AppThemePreset.deepObsidian);
      expect(AppColors.currentPreset, equals(AppThemePreset.deepObsidian));
      expect(AppColors.background, equals(const Color(0xFF0B0D14)));
      expect(AppColors.glassSurface, equals(const Color(0xCC161B26)));
      expect(AppColors.textPrimary, equals(const Color(0xFFF8FAFC)));

      // 2. Render AiToolsView
      await tester.pumpWidget(wrapWithScreenUtil(const AiToolsView()));
      await tester.pumpAndSettle();

      // 3. Verify section header and tools render
      expect(find.text('Get designs done fast with Skills'), findsOneWidget);
      expect(find.text('Remove Background'), findsOneWidget);

      // 4. Find the card container decoration for Remove Background
      final textFinder = find.text('Remove Background');
      expect(textFinder, findsOneWidget);

      final Text textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(AppColors.textPrimary));
      expect(textWidget.style?.color, equals(const Color(0xFFF8FAFC)));

      // Find Container containing the frosted glass styling
      final containers = tester.widgetList<Container>(find.byType(Container));
      final glassCardContainer = containers.firstWhere(
        (c) {
          final dec = c.decoration;
          return dec is BoxDecoration && dec.color == AppColors.glassSurface;
        },
      );
      final BoxDecoration boxDec = glassCardContainer.decoration as BoxDecoration;

      // Assert that card color is the dark obsidian glass surface, NOT white
      expect(boxDec.color, equals(const Color(0xCC161B26)));
      expect(boxDec.color, isNot(equals(Colors.white)));
      expect(boxDec.border?.top.color, equals(AppColors.glassBorder));
    });

    testWidgets('tool cards adapt back to Luminous Aurora light theme seamlessly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Switch theme to Luminous Aurora
      themeController.switchTheme(AppThemePreset.luminousAurora);
      expect(AppColors.currentPreset, equals(AppThemePreset.luminousAurora));
      expect(AppColors.glassSurface, equals(const Color(0xBAFFFFFF)));
      expect(AppColors.textPrimary, equals(const Color(0xFF0F172A)));

      // 2. Render AiToolsView
      await tester.pumpWidget(wrapWithScreenUtil(const AiToolsView()));
      await tester.pumpAndSettle();

      // 3. Find card text and container
      final textFinder = find.text('Remove Background');
      final Text textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.style?.color, equals(const Color(0xFF0F172A)));

      final containers = tester.widgetList<Container>(find.byType(Container));
      final glassCardContainer = containers.firstWhere(
        (c) {
          final dec = c.decoration;
          return dec is BoxDecoration && dec.color == AppColors.glassSurface;
        },
      );
      final BoxDecoration boxDec = glassCardContainer.decoration as BoxDecoration;
      expect(boxDec.color, equals(const Color(0xBAFFFFFF)));
    });
  });
}
