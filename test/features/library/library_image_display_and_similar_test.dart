import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/library/views/cloud_library_view.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/collection_controller.dart';
import 'package:craftai_studio_mobile/features/explore/controllers/explore_controller.dart';
import 'package:craftai_studio_mobile/features/explore/views/explore_category_view.dart';
import 'package:craftai_studio_mobile/features/explore/widgets/explore_card_widget.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/shared/widgets/app_network_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Library Current Section Image Display Tests', () {
    late LibraryController libraryController;

    setUp(() {
      Get.reset();
      Get.put(ShellController());
      libraryController = Get.put(LibraryController());
      Get.put(CollectionController());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Library Current section displays images with BoxFit.contain preserving aspect ratio', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed a job with non-square aspect ratio
      final sampleJob = JobModel(
        jobId: 'job_aspect_test',
        type: 'text_to_image',
        status: 'completed',
        prompt: 'Futuristic architectural skyline at dusk',
        previewUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600',
        creditsDeducted: 1.0,
        aspectRatio: '16:9',
        dimensions: '1920x1080',
        createdAt: DateTime.now(),
      );

      libraryController.myCreations.assignAll([sampleJob]);
      libraryController.isLoading.value = false;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: CloudLibraryView(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify AppNetworkImage is present with BoxFit.contain
      final appNetworkImageFinder = find.byType(AppNetworkImage);
      expect(appNetworkImageFinder, findsOneWidget);

      final appNetworkImageWidget = tester.widget<AppNetworkImage>(appNetworkImageFinder);
      expect(appNetworkImageWidget.fit, equals(BoxFit.contain));

      // 2. Verify prompt text and job elements render cleanly
      expect(find.text('Futuristic architectural skyline at dusk'), findsOneWidget);
    });
  });

  group('Similar Creation Page Category Overlay Suppression Tests', () {
    late ExploreController exploreController;

    setUp(() {
      Get.reset();
      exploreController = Get.put(ExploreController());
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('ExploreCardWidget with showCategory: false suppresses category overlay on image', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final testCard = ExploreCardModel(
        id: 'card_suppress_test',
        title: 'Neon Cyber City',
        previewUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600',
        category: 'Cyberpunk',
        maskedSummary: 'Neon Cyber City',
        fullPrompt: 'Neon Cyber City with rain reflections',
        authorName: 'DigitalArtist',
        authorHandle: '@digital',
        authorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100',
        likeCount: 50,
        remixCount: 10,
        remixFee: 1.0,
        creatorRoyaltyCut: 0.2,
      );

      // Render with showCategory: false (as on Similar Creation page)
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => GetMaterialApp(
            home: Scaffold(
              body: ExploreCardWidget(
                card: testCard,
                index: 0,
                showCategory: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // The category chip 'Cyberpunk' should NOT be present on the image
      expect(find.text('Cyberpunk'), findsNothing);
      // The like button and prompt title remain
      expect(find.text('Neon Cyber City'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('ExploreCategoryView (Similar Creation page) renders cards without category labels on images', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Ensure exploreController has cards
      expect(exploreController.cards.isNotEmpty, isTrue);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const GetMaterialApp(
            home: ExploreCategoryView(category: 'Cyberpunk'),
          ),
        ),
      );
      await tester.pump();

      // On ExploreCategoryView, the AppBar title contains 'Cyberpunk'
      // but each card in the grid has showCategory: false.
      // Therefore, 'Cyberpunk' should only appear once (in the AppBar title), NOT on the images.
      expect(find.text('Cyberpunk'), findsOneWidget);

      // Verify the cards are rendered
      expect(find.byType(ExploreCardWidget), findsWidgets);
      final firstCardWidget = tester.widget<ExploreCardWidget>(find.byType(ExploreCardWidget).first);
      expect(firstCardWidget.showCategory, isFalse);
    });
  });
}

