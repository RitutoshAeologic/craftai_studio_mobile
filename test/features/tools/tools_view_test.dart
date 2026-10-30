import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/tools/views/ai_tools_view.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/views/magic_object_eraser_view.dart';
import 'package:craftai_studio_mobile/features/tools/views/photo_colorizer_view.dart';
import '../studio/studio_responsiveness_test.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put<IStudioRepository>(MockStudioRepository());
    Get.put(ShellController());
    Get.put(StudioController(repository: Get.find<IStudioRepository>()));
    Get.put(ToolsController(repository: Get.find<IStudioRepository>()));
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('AiToolsView renders smoothly without overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const GetMaterialApp(
          home: AiToolsView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Creative Toolbox'), findsOneWidget);
    expect(find.text('AI Background Remover'), findsWidgets);
    expect(find.text('Get designs done fast with Skills'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Upscale 4K'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Upscale 4K'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Marketing Poster'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Marketing Poster'), findsOneWidget);
  });

  testWidgets('Tapping a tool card clears any previously selected photo variable', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final toolsController = Get.find<ToolsController>();
    toolsController.inputImagePath.value = '/path/to/old_photo.jpg';
    toolsController.resultImageUrl.value = 'https://example.com/result.jpg';

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const GetMaterialApp(
          home: AiToolsView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(toolsController.inputImagePath.value, equals('/path/to/old_photo.jpg'));

    // Tap on Magic Object Eraser tool card
    await tester.scrollUntilVisible(
      find.text('Magic Object Eraser'),
      100,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Magic Object Eraser'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify inputImagePath and resultImageUrl are cleared
    expect(toolsController.inputImagePath.value, isNull);
    expect(toolsController.resultImageUrl.value, isNull);
  });

  testWidgets('MagicObjectEraserView clears active session on init', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final toolsController = Get.find<ToolsController>();
    toolsController.inputImagePath.value = '/path/to/old_photo.jpg';

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const GetMaterialApp(
          home: MagicObjectEraserView(),
        ),
      ),
    );
    await tester.pump();

    expect(toolsController.inputImagePath.value, isNull);
  });

  testWidgets('PhotoColorizerView clears active session on init', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);

    final toolsController = Get.find<ToolsController>();
    toolsController.inputImagePath.value = '/path/to/old_photo.jpg';

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const GetMaterialApp(
          home: PhotoColorizerView(),
        ),
      ),
    );
    await tester.pump();

    expect(toolsController.inputImagePath.value, isNull);
  });
}
