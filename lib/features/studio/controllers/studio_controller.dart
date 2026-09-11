import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/data/models/character_model.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import 'package:craftai_studio_mobile/features/library/controllers/library_controller.dart';

class StudioController extends GetxController {
  final TextEditingController promptController = TextEditingController();
  
  final RxInt batchCount = 1.obs;
  final RxBool isSeedLocked = false.obs;
  final RxString selectedAspectRatio = '1:1'.obs;
  final RxString selectedResolution = '2K'.obs;
  final RxString selectedModel = 'flux'.obs;
  
  final RxList<String> referenceImages = <String>[].obs;
  final Rxn<CharacterModel> selectedCharacter = Rxn<CharacterModel>();
  final RxBool isGenerating = false.obs;

  final List<String> aspectRatios = ['Auto', '1:1', '9:16', '16:9', '4:5'];
  final List<String> resolutions = ['HD', '2K', '4K'];

  int get calculatedCreditCost {
    int base = selectedModel.value == 'flux' ? 2 : 4;
    if (selectedResolution.value == '4K') base += 2;
    return base * batchCount.value;
  }

  void setBatchCount(int count) {
    batchCount.value = count;
  }

  void toggleSeedLock() {
    isSeedLocked.value = !isSeedLocked.value;
  }

  void setAspectRatio(String ratio) {
    selectedAspectRatio.value = ratio;
  }

  void setResolution(String res) {
    selectedResolution.value = res;
  }

  void addReferenceImage(String url) {
    if (referenceImages.length < 3) {
      referenceImages.add(url);
      Get.snackbar(
        'Reference Added',
        'Image loaded as style/pose reference',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF151D2F),
        colorText: Colors.white,
      );
    }
  }

  void removeReferenceImage(int index) {
    if (index >= 0 && index < referenceImages.length) {
      referenceImages.removeAt(index);
    }
  }

  void enhancePrompt() {
    final current = promptController.text.trim();
    if (current.isEmpty) {
      promptController.text =
          'Cinematic portrait of a cyberpunk ronin, 85mm f/1.4 lens, volumetric neon rim lighting, wet asphalt reflections, 8k render';
    } else {
      promptController.text =
          '$current, 85mm f/1.4 lens, cinematic lighting, 8k resolution, photorealistic textures';
    }
    Get.snackbar(
      'Magic Prompt Enhanced ✨',
      'Studio tokens and optics injected via Gemini 1.5 Flash',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF151D2F),
      colorText: const Color(0xFF00F2FE),
    );
  }

  void aiEditSubjectLock() {
    final current = promptController.text.trim();
    promptController.text =
        'DO NOT CHANGE THE HUMAN SUBJECT. HUMAN SUBJECT — ABSOLUTE LOCK. $current';
    Get.snackbar(
      'AI Edit Activated ✨',
      'Subject locked: only clothing, background & lighting will adjust',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF151D2F),
      colorText: Colors.purpleAccent,
    );
  }

  void loadPromptFromRemix(ExploreCardModel card) {
    promptController.text = card.maskedSummary.replaceAll(' • [Secret Recipe Encrypted]', '');
    Get.snackbar(
      'Prompt Loaded for Remix',
      'Created by ${card.authorName} (${(card.creatorRoyaltyCut / card.remixFee * 100).toInt()}% royalty to author)',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF151D2F),
      colorText: const Color(0xFF00F2FE),
    );
  }

  Future<void> generateVisual() async {
    final shellCtrl = Get.find<ShellController>();
    final cost = calculatedCreditCost.toDouble();
    if (shellCtrl.userCredits.value < cost) {
      Get.snackbar('Insufficient Credits', 'Please top up your wallet to continue.');
      return;
    }

    isGenerating.value = true;
    shellCtrl.deductCredits(cost);

    // Simulate async serverless GPU execution
    await Future.delayed(const Duration(seconds: 2));

    final libCtrl = Get.find<LibraryController>();
    libCtrl.addNewCreation(
      prompt: promptController.text.isEmpty ? 'Studio Generation' : promptController.text,
      credits: cost,
    );

    isGenerating.value = false;
    shellCtrl.switchTab(2); // navigate to library

    Get.snackbar(
      'Generation Completed ✨',
      'Saved to your Cloud Library for free. Tap to export 4K.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFF151D2F),
      colorText: const Color(0xFF00F2FE),
    );
  }

  @override
  void onClose() {
    promptController.dispose();
    super.onClose();
  }
}
