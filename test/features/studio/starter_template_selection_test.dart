import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import '../../mocks/fake_studio_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StudioController controller;

  setUp(() {
    Get.reset();
    Get.put(ShellController());
    controller = Get.put(StudioController(repository: FakeStudioRepository()));
  });

  tearDown(() {
    Get.reset();
  });

  group('Starter Template Selection & Reactivity Tests', () {
    test('Selecting starter template sets selectedStarterTemplate and prompt text', () {
      expect(controller.selectedStarterTemplate.value, isNull);
      expect(controller.promptController.text, isEmpty);

      final template = controller.starterTemplates[0]; // Cyberpunk Ronin
      controller.selectStarterTemplate(template);

      expect(controller.selectedStarterTemplate.value, template['title']);
      expect(controller.promptController.text, template['prompt']);
    });

    test('Switching to another starter template updates selection and prompt', () {
      final t1 = controller.starterTemplates[0];
      final t2 = controller.starterTemplates[1];

      controller.selectStarterTemplate(t1);
      expect(controller.selectedStarterTemplate.value, t1['title']);

      controller.selectStarterTemplate(t2);
      expect(controller.selectedStarterTemplate.value, t2['title']);
      expect(controller.promptController.text, t2['prompt']);
    });

    test('Tapping same selected template again toggles off and clears prompt', () {
      final t = controller.starterTemplates[0];

      controller.selectStarterTemplate(t);
      expect(controller.selectedStarterTemplate.value, t['title']);

      // Tap again
      controller.selectStarterTemplate(t);
      expect(controller.selectedStarterTemplate.value, isNull);
      expect(controller.promptController.text, isEmpty);
    });

    test('Manually modifying prompt text automatically unselects starter template', () {
      final t = controller.starterTemplates[0];

      controller.selectStarterTemplate(t);
      expect(controller.selectedStarterTemplate.value, t['title']);

      // User types custom addition
      controller.promptController.text = '${t['prompt']} with a red katana';
      expect(controller.selectedStarterTemplate.value, isNull);

      // User reverts back to exact template prompt
      controller.promptController.text = t['prompt']!;
      expect(controller.selectedStarterTemplate.value, t['title']);
    });
  });
}
