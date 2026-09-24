import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';
import 'package:craftai_studio_mobile/features/library/views/creation_detail_view.dart';
import 'package:craftai_studio_mobile/features/library/views/cloud_library_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LibraryController controller;
  late JobModel sampleJob;

  setUp(() {
    Get.testMode = true;
    controller = Get.put<LibraryController>(LibraryController());
    sampleJob = JobModel(
      jobId: 'job_delete_flow_test',
      type: 'IMAGE_GEN',
      status: 'completed',
      prompt: 'Cyberpunk cityscape in neon rain',
      previewUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600',
      creditsDeducted: 2.0,
      createdAt: DateTime.now(),
    );
    controller.myCreations.assignAll([sampleJob]);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => GetMaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('CreationDetailView Deletion Flow Tests', () {
    testWidgets('renders delete action button in CreationDetailView', (tester) async {
      await tester.pumpWidget(buildTestableWidget(CreationDetailView(job: sampleJob)));
      await tester.pump(const Duration(milliseconds: 100));

      final deleteButtonFinder = find.byTooltip('Delete Creation');
      expect(deleteButtonFinder, findsOneWidget);
    });

    testWidgets('tapping delete icon shows confirmation dialog with Cancel and Delete actions', (tester) async {
      await tester.pumpWidget(buildTestableWidget(CreationDetailView(job: sampleJob)));
      await tester.pump(const Duration(milliseconds: 100));

      final deleteButtonFinder = find.byTooltip('Delete Creation');
      await tester.scrollUntilVisible(deleteButtonFinder, 200);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(deleteButtonFinder);
      await tester.pump(const Duration(milliseconds: 100));

      // Dialog title and description
      expect(find.text('Delete Creation?'), findsOneWidget);
      expect(find.textContaining('permanently delete this image'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      // Tap Cancel closes dialog without deleting
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delete Creation?'), findsNothing);
      expect(controller.myCreations.length, equals(1));
    });

    testWidgets('confirming delete in dialog triggers loader and purges from controller', (tester) async {
      await tester.pumpWidget(buildTestableWidget(CreationDetailView(job: sampleJob)));
      await tester.pump(const Duration(milliseconds: 100));

      final deleteButtonFinder = find.byTooltip('Delete Creation');
      await tester.scrollUntilVisible(deleteButtonFinder, 200);
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(deleteButtonFinder);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delete Creation?'), findsOneWidget);

      // Tap Delete
      await tester.tap(find.text('Delete'));
      await tester.pump(const Duration(milliseconds: 200));

      // Subject has been optimistically removed from controller immediately
      expect(controller.myCreations.isEmpty, isTrue);

      // Pump 4 seconds so background async completion finishes
      await tester.pump(const Duration(seconds: 4));
      // Dialog is closed
      expect(find.text('Delete Creation?'), findsNothing);
    });
  });

  group('CloudLibraryView Deletion Flow Tests', () {
    testWidgets('tapping delete icon on card displays confirmation dialog and purges item', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const CloudLibraryView()));
      await tester.pump(const Duration(milliseconds: 100));

      final cardDeleteIcon = find.byIcon(Icons.delete_outline_rounded);
      expect(cardDeleteIcon, findsOneWidget);

      await tester.tap(cardDeleteIcon, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delete Creation?'), findsOneWidget);

      // Confirm Delete
      await tester.tap(find.text('Delete'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(controller.myCreations.isEmpty, isTrue);

      // Pump 4 seconds so background async completion finishes
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Delete Creation?'), findsNothing);
    });
  });
}
