import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/job_model.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LibraryController & Cloud Storage Purge Tests', () {
    late LibraryController controller;

    setUp(() {
      Get.reset();
      controller = Get.put(LibraryController());
    });

    tearDown(() {
      Get.reset();
    });

    test('extractStoragePath correctly resolves varied Supabase URLs and folder patterns', () {
      // 1. Full Supabase public URL
      const url1 = 'https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/public/user_generations/generations/task_123.png';
      expect(LibraryController.extractStoragePath(url1), equals('generations/task_123.png'));

      // 2. Supabase authenticated / signed URL with query params
      const url2 = 'https://txiuwtrmfvceddqsjvhk.supabase.co/storage/v1/object/user_generations/ai_backgrounds/bg_abc.png?token=secret123';
      expect(LibraryController.extractStoragePath(url2), equals('ai_backgrounds/bg_abc.png'));

      // 3. 4K upscale folder
      const url3 = 'https://custom-cdn.com/storage/user_generations/upscaled_4k/4k_photo.png';
      expect(LibraryController.extractStoragePath(url3), equals('upscaled_4k/4k_photo.png'));

      // 4. Product details folder
      const url4 = 'https://custom-cdn.com/product_details/shoe_detail.png';
      expect(LibraryController.extractStoragePath(url4), equals('product_details/shoe_detail.png'));

      // 5. Marketing poster folder
      const url5 = 'https://custom-cdn.com/marketing_posters/summer_sale.png';
      expect(LibraryController.extractStoragePath(url5), equals('marketing_posters/summer_sale.png'));

      // 6. Null / empty string
      expect(LibraryController.extractStoragePath(null), isNull);
      expect(LibraryController.extractStoragePath(''), isNull);
    });

    test('deleteCreation removes item immediately from myCreations list', () async {
      final job1 = JobModel(
        jobId: 'job_test_001',
        type: 'IMAGE_GEN',
        status: 'completed',
        prompt: 'Neon cybernetic katana warrior',
        previewUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600',
        creditsDeducted: 2.0,
        createdAt: DateTime.now(),
      );

      final job2 = JobModel(
        jobId: 'job_test_002',
        type: 'IMAGE_GEN',
        status: 'completed',
        prompt: 'Futuristic floating city in sunset clouds',
        previewUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600',
        creditsDeducted: 4.0,
        createdAt: DateTime.now(),
      );

      controller.myCreations.assignAll([job1, job2]);
      expect(controller.myCreations.length, equals(2));

      // Trigger deletion of job1
      final result = await controller.deleteCreation(job1);

      expect(result, isTrue);
      expect(controller.myCreations.length, equals(1));
      expect(controller.myCreations.first.jobId, equals('job_test_002'));
    });

    test('deleteCreation triggers empty state condition when last item is deleted', () async {
      final singleJob = JobModel(
        jobId: 'job_lonely_001',
        type: 'IMAGE_GEN',
        status: 'completed',
        prompt: 'Single solitary astronaut on moon',
        previewUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600',
        creditsDeducted: 2.0,
        createdAt: DateTime.now(),
      );

      controller.myCreations.assignAll([singleJob]);
      expect(controller.myCreations.isEmpty, isFalse);

      await controller.deleteCreation(singleJob);

      expect(controller.myCreations.isEmpty, isTrue);
    });
  });
}
