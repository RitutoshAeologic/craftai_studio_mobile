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

  testWidgets('ExploreFeedView displays 3 dropdown filters and applies category selection', (WidgetTester tester) async {
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

    // Verify initial state: default filter is 'All'
    expect(controller.selectedCategory.value, 'All');
    expect(find.text('Categories'), findsOneWidget);
    expect(find.text('Models'), findsOneWidget);
    expect(find.text('Aspect Ratio'), findsOneWidget);

    // Tap on Categories dropdown
    final categoryDropdown = find.byType(DropdownButton<String>).first;
    expect(categoryDropdown, findsOneWidget);
    await tester.tap(categoryDropdown);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap 'Anime' in the dropdown menu
    final animeItem = find.text('Anime').last;
    expect(animeItem, findsOneWidget);
    await tester.tap(animeItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify controller value updated
    expect(controller.selectedCategory.value, 'Anime');

    // All displayed cards in masonry grid should belong to 'Anime'
    for (final card in controller.filteredCards) {
      expect(card.category, 'Anime');
    }
  });
}
