import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/prompt_chat_copilot_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/views/prompt_chat_copilot_view.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/core/constants/app_strings.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/copilot_message_model.dart';
import '../../mocks/fake_studio_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudioController studioController;
  late PromptChatCopilotController copilotController;

  setUp(() {
    Get.reset();
    Get.testMode = true;
    Get.put(ShellController());
    studioController = Get.put(StudioController(repository: FakeStudioRepository()));
    copilotController = Get.put(PromptChatCopilotController(repository: FakeStudioRepository()));
  });

  tearDown(() {
    Get.reset();
  });

  group('PromptChatCopilotController.applyPromptToStudio Tests', () {
    test('applyPromptToStudio sets studioController.promptController.text with activeBasePrompt', () {
      copilotController.activeBasePrompt.value = 'Futuristic cyberpunk skyline in neon rain';
      expect(studioController.promptController.text, isEmpty);

      copilotController.applyPromptToStudio();

      expect(studioController.promptController.text, 'Futuristic cyberpunk skyline in neon rain');
    });

    test('applyPromptToStudio with custom promptToUse overrides activeBasePrompt', () {
      copilotController.activeBasePrompt.value = 'Old prompt';
      copilotController.applyPromptToStudio(promptToUse: 'Turn 2 refined prompt: portrait of warrior');

      expect(studioController.promptController.text, 'Turn 2 refined prompt: portrait of warrior');
    });

    test('applyPromptToStudio does not overwrite studio prompt if target is empty', () {
      studioController.promptController.text = 'Existing prompt in studio';
      copilotController.activeBasePrompt.value = '';

      copilotController.applyPromptToStudio();

      expect(studioController.promptController.text, 'Existing prompt in studio');
    });
  });

  group('PromptChatCopilotView Widget Tests', () {
    testWidgets('Tapping Use in Studio in bottom bar updates Studio promptController', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      copilotController.activeBasePrompt.value = 'Hyper-detailed anime hero';

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: PromptChatCopilotView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final useInStudioFinder = find.widgetWithText(OutlinedButton, AppStrings.btnUseInStudio);
      expect(useInStudioFinder, findsOneWidget);

      await tester.tap(useInStudioFinder);
      await tester.pumpAndSettle();

      expect(studioController.promptController.text, 'Hyper-detailed anime hero');
    });

    testWidgets('Tapping Use in Studio on active context card updates Studio promptController', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      copilotController.activeBasePrompt.value = 'Ethereal forest with glowing fireflies';

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: PromptChatCopilotView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cardButton = find.text(AppStrings.btnUseInStudio).first;
      await tester.tap(cardButton);
      await tester.pumpAndSettle();

      expect(studioController.promptController.text, 'Ethereal forest with glowing fireflies');
    });

    testWidgets('Tapping Use in Studio on AI refinement bubble extracts and sets prompt', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      copilotController.activeBasePrompt.value = '';
      copilotController.messages.add(
        CopilotMessage(
          id: 'msg_refined_1',
          text: 'Prompt refined via Groq:\n\n"Neon samurai standing in torrential rain, 8k octane render"',
          isUser: false,
          addedTags: ['rain', 'neon'],
        ),
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: PromptChatCopilotView(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Use in Studio on the message bubble
      final bubbleButton = find.text(AppStrings.btnUseInStudio).first;
      await tester.tap(bubbleButton);
      await tester.pumpAndSettle();

      expect(studioController.promptController.text, 'Neon samurai standing in torrential rain, 8k octane render');
    });
  });
}
