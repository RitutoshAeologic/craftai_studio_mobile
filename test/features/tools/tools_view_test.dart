import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/tools/views/ai_tools_view.dart';
import '../studio/studio_responsiveness_test.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put<IStudioRepository>(MockStudioRepository());
    Get.put(ShellController());
    Get.put(StudioController(repository: Get.find<IStudioRepository>()));
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
}
