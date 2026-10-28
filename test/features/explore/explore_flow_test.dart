import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_feed_view.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_discovery_view.dart';
import 'package:craftai_studio_mobile/features/explore/widgets/image_details_bottom_sheet.dart';
import 'package:craftai_studio_mobile/features/explore/widgets/filter_bottom_sheet.dart';
import 'package:craftai_studio_mobile/features/library/widgets/save_to_collection_sheet.dart';
import 'package:craftai_studio_mobile/features/library/controllers/collection_controller.dart';

void main() {
  setUp(() {
    Get.reset();
    Get.put(ExploreController());
    Get.put(CollectionController());
  });

  Widget createTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, _) => GetMaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  final testCard = ExploreCardModel(
    id: 'test_card_1',
    authorName: 'Neo Akira',
    authorHandle: '@neo_akira',
    authorAvatar: 'https://example.com/avatar.jpg',
    title: 'Cyber Ronin in Rain',
    previewUrl: 'https://example.com/ronin.jpg',
    category: 'Cyberpunk',
    maskedSummary: 'Cyber Ronin • Wet Neon Street • 85mm Bokeh',
    remixFee: 4.0,
    creatorRoyaltyCut: 1.6,
    remixCount: 342,
    likeCount: 890,
    modelUsed: 'SDXL-Lightning RealVisXL v4.0',
    toolApplied: 'Text to Image',
    aspectRatio: '16:9',
    dimensions: '1920x1080',
    seed: 4291823,
    costCredits: 2.0,
  );

  group('Explore Feed & Scattered Masonry Tests', () {
    testWidgets('ExploreFeedView renders header title and category pills', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const ExploreFeedView()));
      await tester.pump();

      expect(find.text('Explore Feed'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Photorealism'), findsAtLeastNWidgets(1));
      expect(find.text('Anime'), findsAtLeastNWidgets(1));
      expect(find.text('Cyberpunk'), findsAtLeastNWidgets(1));
    });

    testWidgets('Tapping Filter icon opens FilterBottomSheet', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const ExploreFeedView()));
      await tester.pump();

      final filterButton = find.byTooltip('Filter Creations');
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Filter Feed'), findsOneWidget);
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.text('Reset All'), findsOneWidget);
    });
  });

  group('ExploreDiscoveryView (Screen 2) Tests', () {
    testWidgets('ExploreDiscoveryView renders Similar Carousel and Community Stream', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(ExploreDiscoveryView(selectedCard: testCard)));
      await tester.pump();

      expect(find.text('Explore & Discover'), findsOneWidget);
      expect(find.textContaining('Similar Creations'), findsOneWidget);
      expect(find.text('More from the Community'), findsOneWidget);
    });
  });

  group('ImageDetailsBottomSheet (Screen 3) Cognitive UX Tests', () {
    testWidgets('ImageDetailsBottomSheet renders Miller 3-chunk layout and 1-Primary CTA', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(ImageDetailsBottomSheet(card: testCard)));
      await tester.pump();

      // Chunk 1: Visual Identity
      expect(find.text('Neo Akira'), findsOneWidget);
      expect(find.text('@neo_akira'), findsOneWidget);
      expect(find.text('890'), findsOneWidget);

      // Chunk 2: Recipe
      expect(find.text('Prompt Recipe'), findsOneWidget);
      expect(find.text('Copy Prompt'), findsOneWidget);
      expect(find.text('SDXL-Lightning RealVisXL v4.0'), findsOneWidget);

      // Chunk 3: Technical Parameters Grid
      expect(find.text('Generation Parameters'), findsOneWidget);
      expect(find.text('16:9'), findsOneWidget);
      expect(find.text('1920x1080'), findsOneWidget);
      expect(find.text('#4291823'), findsOneWidget);
      expect(find.text('2.0 Credits'), findsOneWidget);

      // Hick's 1-CTA & Thumb Zone Sticky Bar
      expect(find.text('⚡ Remix in Studio'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Use Ref'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });
  });

  group('SaveToCollectionSheet Tests', () {
    testWidgets('SaveToCollectionSheet renders title and create folder action', (tester) async {
      await tester.pumpWidget(createTestWidget(const SaveToCollectionSheet(
        itemId: 'test_card_1',
        imageUrl: 'https://example.com/ronin.jpg',
      )));
      await tester.pump();

      expect(find.text('Save to Collection'), findsOneWidget);
      expect(find.text('Create New Collection'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });
  });
}
