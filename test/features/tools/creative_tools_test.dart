import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/tools/controllers/tools_controller.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/ai_backgrounds_sheet.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/ai_expand_sheet.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/upscale_sheet.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/product_detail_sheet.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/marketing_poster_sheet.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/tool_result_preview_sheet.dart';
import 'package:craftai_studio_mobile/shared/widgets/before_after_slider.dart';
import '../../mocks/fake_studio_repository.dart';

class MockCreativeToolsRepository extends FakeStudioRepository {
  String? lastBgMode;
  String? lastExpandRatio;
  int? lastScaleFactor;
  String? lastProductName;
  String? lastPosterTopic;

  @override
  Future<StudioResult<String>> generateAiBackground({
    required String imageUrl,
    String mode = 'pure_white',
    String? customBackdrop,
    String aspectRatio = 'Auto',
    String quality = '1k',
    String? userId,
  }) async {
    lastBgMode = mode;
    return (data: 'https://images.unsplash.com/mock-ai-bg-result', failure: null);
  }

  @override
  Future<StudioResult<String>> executeAiExpand({
    required String imageUrl,
    String targetRatio = '16:9',
    String quality = '1k',
    String? userId,
  }) async {
    lastExpandRatio = targetRatio;
    return (data: 'https://images.unsplash.com/mock-ai-expand-result', failure: null);
  }

  @override
  Future<StudioResult<String>> upscaleImage({
    required String imageUrl,
    int scaleFactor = 2,
    String? userId,
  }) async {
    lastScaleFactor = scaleFactor;
    return (data: 'https://images.unsplash.com/mock-upscale-result', failure: null);
  }

  @override
  Future<StudioResult<String>> executeProductDetail({
    String? imageUrl,
    String productName = 'Commercial Product',
    String aspectRatio = '4:5',
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async {
    lastProductName = productName;
    return (data: 'https://images.unsplash.com/mock-product-detail-result', failure: null);
  }

  @override
  Future<StudioResult<String>> generateMarketingPoster({
    required String topic,
    String? imageUrl,
    String category = 'Promotion',
    String aspectRatio = '4:5',
    String? headline,
    String language = 'Auto',
    String quality = '1k',
    String? userId,
  }) async {
    lastPosterTopic = topic;
    return (data: 'https://images.unsplash.com/mock-marketing-poster-result', failure: null);
  }
}

Widget buildTestableWidget(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (_, __) => GetMaterialApp(
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  late MockCreativeToolsRepository mockRepo;
  late ShellController shellController;
  late LibraryController libraryController;
  late ToolsController toolsController;

  setUp(() {
    Get.reset();
    mockRepo = MockCreativeToolsRepository();
    Get.put<IStudioRepository>(mockRepo);
    shellController = Get.put(ShellController());
    libraryController = Get.put(LibraryController());
    Get.put(StudioController(repository: mockRepo));
    toolsController = Get.put(ToolsController(repository: mockRepo));
    shellController.userCredits.value = 500.0;
  });

  tearDown(() {
    Get.reset();
  });

  group('Creative Tools Controller Pipelines', () {
    test('runAiBackground handles pure_white as zero-token free tier', () async {
      const initialCredits = 500.0;
      shellController.userCredits.value = initialCredits;

      final res = await toolsController.runAiBackground(
        path: 'https://images.unsplash.com/photo-source',
        mode: 'pure_white',
        quality: '1k',
      );

      expect(res, equals('https://images.unsplash.com/mock-ai-bg-result'));
      expect(toolsController.resultImageUrl.value, equals(res));
      expect(mockRepo.lastBgMode, equals('pure_white'));
      expect(shellController.userCredits.value, equals(initialCredits)); // Zero cost
      expect(libraryController.myCreations.first.type, equals('AI_BACKGROUND'));
    });

    test('runAiBackground deducts 10 credits in smart mode', () async {
      const initialCredits = 500.0;
      shellController.userCredits.value = initialCredits;

      final res = await toolsController.runAiBackground(
        path: 'https://images.unsplash.com/photo-source',
        mode: 'smart',
        quality: '1k',
      );

      expect(res, equals('https://images.unsplash.com/mock-ai-bg-result'));
      expect(toolsController.resultImageUrl.value, equals(res));
      expect(mockRepo.lastBgMode, equals('smart'));
      expect(shellController.userCredits.value, equals(initialCredits - 10.0));
    });

    test('runAiExpand handles 16:9 canvas outpainting', () async {
      const initialCredits = 200.0;
      shellController.userCredits.value = initialCredits;

      final res = await toolsController.runAiExpand(
        path: 'https://images.unsplash.com/photo-source',
        targetRatio: '16:9',
        quality: '1k',
      );

      expect(res, equals('https://images.unsplash.com/mock-ai-expand-result'));
      expect(mockRepo.lastExpandRatio, equals('16:9'));
      expect(shellController.userCredits.value, equals(initialCredits - 10.0));
      expect(libraryController.myCreations.first.type, equals('AI_EXPAND'));
    });

    test('runUpscale handles 4x enhancement with 2 credits deduction', () async {
      const initialCredits = 100.0;
      shellController.userCredits.value = initialCredits;

      final res = await toolsController.runUpscale(
        path: 'https://images.unsplash.com/photo-source',
        scaleFactor: 4,
      );

      expect(res, equals('https://images.unsplash.com/mock-upscale-result'));
      expect(mockRepo.lastScaleFactor, equals(4));
      expect(shellController.userCredits.value, equals(initialCredits - 2.0));
      expect(libraryController.myCreations.first.type, equals('UPSCALE_4K'));
    });

    test('runProductDetail creates listing set for specified product', () async {
      const initialCredits = 300.0;
      shellController.userCredits.value = initialCredits;

      final res = await toolsController.runProductDetail(
        path: 'https://images.unsplash.com/photo-source',
        productName: 'Wireless Noise Canceling Headphones',
        aspectRatio: '4:5',
      );

      expect(res, equals('https://images.unsplash.com/mock-product-detail-result'));
      expect(mockRepo.lastProductName, equals('Wireless Noise Canceling Headphones'));
      expect(shellController.userCredits.value, equals(initialCredits - 10.0));
      expect(libraryController.myCreations.first.type, equals('PRODUCT_DETAIL'));
    });

    test('runMarketingPoster designs commercial poster for topic', () async {
      const initialCredits = 400.0;
      shellController.userCredits.value = initialCredits;

      final res = await toolsController.runMarketingPoster(
        topic: 'Summer Cold Brew Launch',
        category: 'Beverage',
        aspectRatio: '9:16',
        headline: 'Cold. Bold. Refreshing.',
        quality: '2k',
      );

      expect(res, equals('https://images.unsplash.com/mock-marketing-poster-result'));
      expect(mockRepo.lastPosterTopic, equals('Summer Cold Brew Launch'));
      // 2k quality costs 14 credits
      expect(shellController.userCredits.value, equals(initialCredits - 14.0));
    });

    test('Preflight credit check aborts when user credits are insufficient', () async {
      shellController.userCredits.value = 5.0; // Needs 10.0

      final res = await toolsController.runAiBackground(
        path: 'https://images.unsplash.com/photo-source',
        mode: 'smart',
        quality: '1k',
      );

      expect(res, isNull);
      expect(shellController.userCredits.value, equals(5.0)); // No credits deducted
    });
  });

  group('Creative Tools Sheets UI Responsiveness', () {
    testWidgets('AiBackgroundsSheet renders without overflow', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AiBackgroundsSheet()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI Backgrounds'), findsOneWidget);
      expect(find.text('Choose a background'), findsOneWidget);
      expect(find.text('Pure white'), findsOneWidget);
      expect(find.text('Smart'), findsOneWidget);
      expect(find.text('Replace background ✦ 10'), findsOneWidget);
    });

    testWidgets('AiExpandSheet renders without overflow', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AiExpandSheet()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI Expand'), findsOneWidget);
      expect(find.text('Target ratio'), findsOneWidget);
      expect(find.text('16:9'), findsOneWidget);
      expect(find.text('Expand image ✦ 10'), findsOneWidget);
    });

    testWidgets('UpscaleSheet renders without overflow', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const UpscaleSheet()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Upscale 4K'), findsOneWidget);
      expect(find.text('Resolution multiplier'), findsOneWidget);
      expect(find.text('2X Super HD'), findsOneWidget);
      expect(find.text('4X Master Ultra'), findsOneWidget);
      expect(find.text('Upscale to 4K ✦ 2'), findsOneWidget);
    });

    testWidgets('ProductDetailSheet renders without overflow', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProductDetailSheet()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Product Detail Images'), findsOneWidget);
      expect(find.text('Set up the basics'), findsOneWidget);
      expect(find.text('Generate Listing Set ✦ 10'), findsOneWidget);
    });

    testWidgets('MarketingPosterSheet renders without overflow', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const MarketingPosterSheet()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Marketing Poster'), findsOneWidget);
      expect(find.text('Set up the basics'), findsOneWidget);
      expect(find.text('Generate Poster ✦ 10'), findsOneWidget);
    });
  });

  group('ToolResultPreviewSheet Interactive UI', () {
    testWidgets('Renders BeforeAfterSlider when enableBeforeAfter is true', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ToolResultPreviewSheet(
            title: 'AI Backgrounds',
            resultImageUrl: 'https://images.unsplash.com/mock-result',
            originalImageUrl: 'https://images.unsplash.com/mock-original',
            creditsUsed: 10.0,
            badgeText: 'Pure White • 1k Quality',
            enableBeforeAfter: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI Backgrounds'), findsOneWidget);
      expect(find.text('Pure White • 1k Quality'), findsOneWidget);
      expect(find.byType(BeforeAfterSlider), findsOneWidget);
      expect(find.text('⚡ Remix in Lab (Chat)'), findsOneWidget);
      expect(find.text('Studio Canvas'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Renders zoom preview when enableBeforeAfter is false', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ToolResultPreviewSheet(
            title: 'AI Expand',
            resultImageUrl: 'https://images.unsplash.com/mock-result',
            creditsUsed: 10.0,
            badgeText: 'Target Ratio: 16:9 • 1k',
            enableBeforeAfter: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('AI Expand'), findsOneWidget);
      expect(find.text('Target Ratio: 16:9 • 1k'), findsOneWidget);
      expect(find.byType(BeforeAfterSlider), findsNothing);
      expect(find.text('⚡ Remix in Lab (Chat)'), findsOneWidget);
    });
  });
}
