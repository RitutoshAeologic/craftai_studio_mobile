import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:craftai_studio_mobile/core/network/api_error.dart';
import 'package:craftai_studio_mobile/core/network/api_error_handler.dart';
import 'package:craftai_studio_mobile/core/network/network_fallback_interceptor.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/studio/domain/failures/studio_failure.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/ai_model_item.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/generation_dispatch_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/models/prompt_expand_model.dart';
import 'package:craftai_studio_mobile/features/studio/domain/repositories/i_studio_repository.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_error_sheet.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/widgets/studio_model_sheet.dart';
import 'package:craftai_studio_mobile/features/tools/domain/models/poster_layout_model.dart';
import 'package:craftai_studio_mobile/features/tools/widgets/poster_canvas_preview.dart';
import 'package:craftai_studio_mobile/features/wallet/widgets/wallet_top_up_sheet.dart';
import 'package:craftai_studio_mobile/shared/utils/reference_image_uploader.dart';
import '../../mocks/fake_studio_repository.dart';

class _GatewayMockStudioRepository extends FakeStudioRepository {
  List<AiModelItem>? modelsToReturn;
  bool shouldFailModels = false;
  StudioFailure? dispatchFailure;
  String? capturedIdempotencyKey;
  bool? capturedEnhancePrompt;
  String? capturedQuality;
  String? capturedModel;
  List<String>? capturedFaceUrls;

  @override
  Future<StudioResult<List<AiModelItem>>> fetchModels() async {
    if (shouldFailModels) {
      return (data: null, failure: const StudioNetworkFailure('Offline'));
    }
    return (
      data: modelsToReturn ?? AiModelItem.defaultSeedCatalog,
      failure: null,
    );
  }

  @override
  Future<StudioResult<GenerationDispatchModel>> dispatchGeneration({
    required String prompt,
    String? characterId,
    List<String>? faceReferenceUrls,
    String? negativePrompt,
    int? seed,
    Map<String, dynamic>? structuredMetadata,
    int width = 1024,
    int height = 1024,
    String? model,
    String? remixedFromPromptId,
    String? quality,
    bool enhancePrompt = false,
    String? idempotencyKey,
  }) async {
    capturedIdempotencyKey = idempotencyKey;
    capturedEnhancePrompt = enhancePrompt;
    capturedQuality = quality;
    capturedModel = model;
    capturedFaceUrls = faceReferenceUrls;

    if (dispatchFailure != null) {
      return (data: null, failure: dispatchFailure);
    }

    return (
      data: const GenerationDispatchModel(
        taskId: 'task_gateway_1',
        tier: 'Tier 0',
        status: 'completed',
        directImageUrl: 'https://cdn.craftai.studio/gen/test.webp',
      ),
      failure: null,
    );
  }
}

class _RetryingAdapter implements HttpClientAdapter {
  final List<String?> seenIdempotencyKeys = [];
  int callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    callCount++;
    final data = options.data is Map ? options.data as Map : {};
    seenIdempotencyKeys.add(data['idempotency_key'] as String?);
    if (callCount == 1) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Simulated primary drop',
      );
    }
    return ResponseBody.fromString(
      jsonEncode({'task_id': 'retried_ok'}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Track 4 AI Gateway Mobile Tests', () {
    late ShellController shellController;
    late _GatewayMockStudioRepository mockRepo;

    setUp(() {
      Get.reset();
      shellController = Get.put(ShellController());
      shellController.userCredits.value = 100.0;
      Get.put(LibraryController());
      mockRepo = _GatewayMockStudioRepository();
    });

    tearDown(() {
      Get.reset();
    });

    test('MOB-1: StudioController seeds offline catalog when fetchModels fails', () async {
      mockRepo.shouldFailModels = true;
      final ctrl = Get.put(StudioController(repository: mockRepo));
      await ctrl.fetchAvailableModels();

      expect(ctrl.catalogModels.length, greaterThanOrEqualTo(3));
      expect(ctrl.catalogModels.any((m) => m.modelKey == 'auto'), isTrue);
      expect(ctrl.catalogModels.any((m) => m.modelKey == 'local_sdxl'), isTrue);
      expect(ctrl.catalogModels.any((m) => m.modelKey == 'flux_schnell'), isTrue);
      expect(ctrl.selectedModel.value, 'auto');
    });

    testWidgets('MOB-1: StudioModelSheet renders capability tags and disables unavailable/incompatible models',
        (tester) async {
      mockRepo.modelsToReturn = [
        const AiModelItem(
          modelKey: 'local_sdxl',
          displayName: 'Local SDXL',
          providerKey: 'local',
          tasks: ['text_to_image', 'image_edit', 'face_lock_remix'],
          tier: 'economy',
          creditCost: 2.0,
          isAvailable: true,
          activeMode: 'local_fallback',
        ),
        const AiModelItem(
          modelKey: 'flux_pulid_facelock',
          displayName: 'FLUX PuLID Face-Lock',
          providerKey: 'fal',
          tasks: ['face_lock_remix'],
          tier: 'premium',
          creditCost: 4.0,
          isAvailable: true,
          activeMode: 'paid_api',
          capabilities: {'supports_facelock': true},
        ),
        const AiModelItem(
          modelKey: 'gpt_image_1',
          displayName: 'GPT Image 1',
          providerKey: 'openai',
          tasks: ['text_to_image', 'image_edit'],
          tier: 'premium',
          creditCost: 5.0,
          isAvailable: false,
          activeMode: 'paid_api',
        ),
      ];

      final ctrl = Get.put(StudioController(repository: mockRepo));
      await ctrl.fetchAvailableModels();

      // In text_to_image mode, flux_pulid_facelock is incompatible and gpt_image_1 has isAvailable=false
      expect(ctrl.activeStudioTask, 'text_to_image');
      ctrl.setModel('gpt_image_1');
      expect(ctrl.selectedModel.value, 'auto', reason: 'Unavailable model cannot be selected');
      ctrl.setModel('flux_pulid_facelock');
      expect(ctrl.selectedModel.value, 'auto', reason: 'Incompatible task model cannot be selected');

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const GetMaterialApp(
            home: Scaffold(body: StudioModelSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Auto (Recommended)'), findsOneWidget);
      expect(find.text('Local SDXL'), findsOneWidget);
      expect(find.text('FLUX PuLID Face-Lock'), findsOneWidget);
      expect(find.text('GPT Image 1'), findsOneWidget);
      expect(find.text('HD Cloud'), findsNWidgets(2));
      expect(find.text('Local Engine'), findsNWidgets(2));
      expect(find.text('Face-Lock'), findsWidgets);
      expect(find.text('API key not configured'), findsOneWidget);
      expect(find.text('Unsupported in text_to_image mode'), findsOneWidget);
    });

    test('MOB-2: generateVisual sends idempotency_key, quality, enhance_prompt and blocks localhost selfie URLs',
        () async {
      final ctrl = Get.put(StudioController(repository: mockRepo));
      ctrl.promptController.text = 'Minimalist mountain sunrise';
      ctrl.enhancePromptOnDispatch.value = true;
      ctrl.selectedResolution.value = '4K';

      await ctrl.generateVisual();

      expect(mockRepo.capturedIdempotencyKey, isNotNull);
      expect(mockRepo.capturedIdempotencyKey!.length, greaterThan(20));
      expect(mockRepo.capturedQuality, 'premium');
      expect(mockRepo.capturedEnhancePrompt, isTrue);

      // Remix forces enhance_prompt=false and accepts only https:// cloud URLs
      ctrl.remixedFromPromptId.value = '10000000-0000-4000-8000-000000000001';
      ctrl.referenceImages.assignAll(['https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/selfies/a.jpg']);
      await ctrl.generateVisual();
      expect(mockRepo.capturedEnhancePrompt, isFalse);
      expect(mockRepo.capturedFaceUrls, [
        'https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/selfies/a.jpg',
      ]);

      // Localhost URL must be rejected by SSRF guard
      expect(ReferenceImageUploader.isValidCloudHttpsUrl('http://127.0.0.1:8000/test.jpg'), isFalse);
      expect(ReferenceImageUploader.isValidCloudHttpsUrl('https://localhost/test.jpg'), isFalse);
      expect(ReferenceImageUploader.isValidCloudHttpsUrl('https://cdn.craftai.studio/selfie.jpg'), isTrue);
    });

    test('MOB-2: Dio retry interceptor preserves exact idempotency_key across retries', () async {
      final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000/api/v1'));
      final adapter = _RetryingAdapter();
      dio.httpClientAdapter = adapter;
      dio.interceptors.add(
        NetworkFallbackInterceptor(
          dio,
          fallbackUrls: const ['http://10.0.2.2:8000/api/v1'],
        ),
      );

      final res = await dio.post(
        '/prompt-engineering/generation/dispatch',
        data: {
          'prompt': 'test',
          'idempotency_key': 'uuid-fixed-1234',
        },
      );

      expect(res.statusCode, 200);
      expect(adapter.callCount, 2);
      expect(adapter.seenIdempotencyKeys, ['uuid-fixed-1234', 'uuid-fixed-1234']);
    });

    test('MOB-2: ApiErrorHandler maps HTTP 402 and HTTP 400 correctly', () {
      final err402 = DioException(
        requestOptions: RequestOptions(path: '/prompt-engineering/generation/dispatch'),
        response: Response(
          requestOptions: RequestOptions(path: '/prompt-engineering/generation/dispatch'),
          statusCode: 402,
          data: {'detail': 'Insufficient credits for gpt_image_1'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(ApiErrorHandler.parse(err402), isA<InsufficientCreditsException>());
      final failure402 = ApiErrorHandler.toStudioFailure(err402);
      expect(failure402, isA<StudioInsufficientCreditsFailure>());
      expect(failure402.message, contains('Insufficient credits'));

      final err400 = DioException(
        requestOptions: RequestOptions(path: '/prompt-engineering/generation/dispatch'),
        response: Response(
          requestOptions: RequestOptions(path: '/prompt-engineering/generation/dispatch'),
          statusCode: 400,
          data: {'detail': 'Model gpt_image_1 is unavailable'},
        ),
        type: DioExceptionType.badResponse,
      );
      final failure400 = ApiErrorHandler.toStudioFailure(err400);
      expect(failure400, isA<StudioValidationFailure>());
      expect(failure400.code, 'BAD_REQUEST_400');
    });

    testWidgets('MOB-2: HTTP 402 opens WalletTopUpSheet and HTTP 400 shows Switch-to-Auto StudioErrorSheet',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => const GetMaterialApp(home: Scaffold(body: SizedBox())),
        ),
      );

      final ctrl = Get.put(StudioController(repository: mockRepo));
      ctrl.promptController.text = 'Test prompt';

      // 402 -> WalletTopUpSheet
      mockRepo.dispatchFailure = const StudioInsufficientCreditsFailure('Need more credits');
      await ctrl.generateVisual();
      await tester.pumpAndSettle();
      expect(find.byType(WalletTopUpSheet), findsOneWidget);
      expect(shellController.userCredits.value, 100.0);

      Get.back();
      await tester.pumpAndSettle();

      // 400 -> StudioErrorSheet with Use Auto button
      mockRepo.dispatchFailure = const StudioValidationFailure('Model unavailable', 'BAD_REQUEST_400');
      await ctrl.generateVisual();
      await tester.pumpAndSettle();
      expect(find.byType(StudioErrorSheet), findsOneWidget);
      expect(find.text('Use Auto'), findsOneWidget);
    });

    test('MOB-3: PromptExpandModel parses optional subject, environment, lighting, camera, negative_prompt', () {
      final parsed = PromptExpandModel.fromJson({
        'master_prompt': 'Cinematic espresso pour',
        'model_used': 'openrouter/auto',
        'structured_metadata': {
          'subject': 'Artisan espresso shot',
          'environment': 'Warm wood cafe counter',
          'lighting': 'Golden morning rim light',
          'camera': '85mm f/1.8 macro',
          'negative_prompt': 'blurry, watermark',
        },
      });

      expect(parsed.masterPrompt, 'Cinematic espresso pour');
      expect(parsed.negativePrompt, 'blurry, watermark');
      expect(parsed.structuredMetadata?.subject, 'Artisan espresso shot');
      expect(parsed.structuredMetadata?.environment, 'Warm wood cafe counter');
      expect(parsed.structuredMetadata?.lighting, 'Golden morning rim light');
      expect(parsed.structuredMetadata?.camera, '85mm f/1.8 macro');
      expect(parsed.structuredMetadata?.cameraOptics, '85mm f/1.8 macro');

      // Backward compatibility: master_prompt only
      final legacy = PromptExpandModel.fromJson({'master_prompt': 'Simple legacy prompt'});
      expect(legacy.masterPrompt, 'Simple legacy prompt');
      expect(legacy.structuredMetadata, isNull);
    });

    testWidgets('MOB-3: PosterLayoutTemplate & PosterCanvasPreview render normalized 0.0-1.0 layout',
        (tester) async {
      final layout = PosterLayoutTemplate.fromJson({
        'template_id': 'remote_1',
        'category': 'Flash Sale',
        'background_start': '#111827',
        'background_end': '#312E81',
        'elements': [
          {'id': 'bg', 'type': 'image', 'x': 0.1, 'y': 0.2, 'width': 0.8, 'height': 0.5},
          {'id': 'h', 'type': 'headline', 'x': 0.1, 'y': 0.05, 'width': 0.8, 'height': 0.12},
        ],
      });

      expect(layout.elements.length, 2);
      expect(layout.elements.first.x, 0.1);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, __) => MaterialApp(
            home: Scaffold(
              body: PosterCanvasPreview(
                layout: layout,
                aspectRatio: '4:5',
                topic: 'Summer Coffee',
                headline: '50% OFF',
                subtext: 'Limited Time',
                discountBadge: 'SALE',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(InteractiveViewer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
