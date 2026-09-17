import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_feed_view.dart';

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ExploreFeedView category chip changes selection and styling on tap', (WidgetTester tester) async {
    final controller = Get.put(ExploreController());

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => const GetMaterialApp(
          home: ExploreFeedView(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.selectedCategory.value, 'All');

    // Tap on 'Anime' chip
    final animeChip = find.text('Anime').first;
    expect(animeChip, findsOneWidget);
    await tester.tap(animeChip);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.selectedCategory.value, 'Anime');

    // Verify styling contrast: active chip has white text, inactive chip has textSecondary
    final Text animeTextWidget = tester.widget(find.text('Anime').first);
    expect(animeTextWidget.style?.color, Colors.white);

    final Text allTextWidget = tester.widget(find.text('All').first);
    expect(allTextWidget.style?.color, isNot(Colors.white));

    // All displayed cards in masonry grid should belong to 'Anime'
    for (final card in controller.filteredCards) {
      expect(card.category, 'Anime');
    }
  });
}
