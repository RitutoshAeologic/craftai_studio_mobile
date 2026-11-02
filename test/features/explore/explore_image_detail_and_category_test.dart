import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_image_detail_view.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_category_view.dart';
import 'package:craftai_studio_mobile/features/explore/widgets/explore_card_widget.dart';
import 'package:craftai_studio_mobile/features/library/controllers/collection_controller.dart';

void main() {
  late ExploreController exploreController;

  setUp(() {
    Get.reset();
    exploreController = Get.put(ExploreController());
    Get.put(CollectionController());
  });

  tearDown(() {
    Get.reset();
  });

  Widget createTestWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(393, 852),
      minTextAdapt: true,
      builder: (context, _) => GetMaterialApp(
        home: child,
      ),
    );
  }

  final testCard = ExploreCardModel(
    id: 'test_cyber_ronin',
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

  group('ExploreImageDetailView Full-Page Screen Tests', () {
    testWidgets('Renders full-page AppBar, 3 visual chunks, and bottom sticky bar', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(ExploreImageDetailView(card: testCard)));
      await tester.pump();

      // Verify AppBar
      expect(find.text('Cyber Ronin in Rain'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
      expect(find.byIcon(Icons.share_outlined), findsAtLeastNWidgets(1));

      // Verify Chunk 1: Visual Identity
      expect(find.text('Cyberpunk'), findsAtLeastNWidgets(1));
      expect(find.text('Neo Akira'), findsOneWidget);
      expect(find.text('@neo_akira'), findsOneWidget);
      expect(find.text('890'), findsOneWidget);

      // Verify Chunk 2: Recipe
      expect(find.text('Prompt Recipe'), findsOneWidget);
      expect(find.text('Copy Prompt'), findsOneWidget);
      expect(find.text('SDXL-Lightning RealVisXL v4.0'), findsOneWidget);

      // Verify Chunk 3: Technical Parameters
      expect(find.text('Generation Parameters'), findsOneWidget);
      expect(find.text('16:9'), findsOneWidget);
      expect(find.text('1920x1080'), findsOneWidget);
      expect(find.text('#4291823'), findsOneWidget);
      expect(find.text('2.0 Credits'), findsOneWidget);

      // Verify Sticky Ergonomic Bottom Bar
      expect(find.text('⚡ Remix in Studio'), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Use Ref'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('Renders Similar Creations section at the bottom in sketcher-style layout', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(ExploreImageDetailView(card: testCard)));
      await tester.pump();

      // Verify Similar Creations header
      expect(find.text('Similar Creations'), findsOneWidget);
      expect(find.text('View All (Cyberpunk)'), findsOneWidget);

      // Scroll down to bring similar creations masonry grid into view
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
      await tester.pump();

      // Verify that similar cards are rendered using ExploreCardWidget
      expect(find.byType(ExploreCardWidget), findsWidgets);
    });

    testWidgets('Tapping category chip on full-page details navigates to ExploreCategoryView', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(ExploreImageDetailView(card: testCard)));
      await tester.pump();

      // Tap the category badge on the image
      final categoryBadge = find.text('Cyberpunk').first;
      await tester.tap(categoryBadge);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies navigation to ExploreCategoryView
      expect(find.byType(ExploreCategoryView), findsOneWidget);
      expect(find.text('Cyberpunk'), findsWidgets);
    });

    testWidgets('Interactive like button increments like count and toggles heart icon', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Add testCard to controller.cards so live like works
      exploreController.cards.add(testCard);

      await tester.pumpWidget(createTestWidget(ExploreImageDetailView(card: testCard)));
      await tester.pump();

      expect(find.text('890'), findsOneWidget);

      final likeButton = find.byIcon(Icons.favorite_border).first;
      await tester.tap(likeButton);
      await tester.pump();

      expect(find.text('891'), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });
  });

  group('ExploreCategoryView Tests', () {
    testWidgets('ExploreCategoryView renders title, creation count, and filtered cards in sketcher layout', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const ExploreCategoryView(category: 'Cyberpunk')));
      await tester.pump();

      // Verify category title
      expect(find.text('Cyberpunk'), findsAtLeastNWidgets(1));

      // Verify creation count
      final cyberpunkCount = exploreController.cards
          .where((c) => c.category.toLowerCase() == 'cyberpunk')
          .length;
      expect(find.text('$cyberpunkCount creations'), findsOneWidget);

      // Verify cards in category are rendered in sketcher masonry layout
      expect(find.byType(ExploreCardWidget), findsWidgets);
    });

    testWidgets('ExploreCategoryView shows empty state when no creations exist for category', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(const ExploreCategoryView(category: 'NonExistentCategory')));
      await tester.pump();

      expect(find.text('No creations found in NonExistentCategory'), findsOneWidget);
      expect(find.byIcon(Icons.image_search), findsOneWidget);
    });
  });

  group('ExploreCardWidget Navigation Tests', () {
    testWidgets('Clicking photo on ExploreCardWidget navigates to ExploreImageDetailView', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(Scaffold(
        body: ListView(
          children: [
            SizedBox(
              width: 200,
              child: ExploreCardWidget(card: testCard, index: 0),
            ),
          ],
        ),
      )));
      await tester.pump();

      // Tap on the card title / photo body (not the category badge)
      final titleFinder = find.text('Cyber Ronin in Rain');
      await tester.tap(titleFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies navigation to ExploreImageDetailView
      expect(find.byType(ExploreImageDetailView), findsOneWidget);
      expect(find.text('Prompt Recipe'), findsOneWidget);
      expect(find.text('⚡ Remix in Studio'), findsOneWidget);
    });

    testWidgets('Clicking category badge on ExploreCardWidget navigates to ExploreCategoryView', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget(Scaffold(
        body: ListView(
          children: [
            SizedBox(
              width: 200,
              child: ExploreCardWidget(card: testCard, index: 0),
            ),
          ],
        ),
      )));
      await tester.pump();

      // Tap specifically on the category pill
      final categoryBadge = find.text('Cyberpunk');
      await tester.tap(categoryBadge);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies navigation to ExploreCategoryView
      expect(find.byType(ExploreCategoryView), findsOneWidget);
    });
  });
}
