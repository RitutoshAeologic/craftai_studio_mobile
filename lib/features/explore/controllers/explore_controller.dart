import 'package:get/get.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/studio/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';

class ExploreController extends GetxController {
  final RxString selectedCategory = 'All'.obs;
  final RxList<String> categories = <String>[
    'All',
    'Anime',
    'Photorealism',
    'Cyberpunk',
    '3D Render',
    'Product',
    'Logo',
  ].obs;

  final RxList<ExploreCardModel> cards = <ExploreCardModel>[
    ExploreCardModel(
      id: '1',
      authorName: 'Neo Akira',
      authorHandle: '@neo_akira',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop',
      title: 'Cyber Ronin in Rain',
      previewUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop',
      category: 'Cyberpunk',
      maskedSummary: 'Cyber Ronin • Wet Neon Street • 85mm Bokeh • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 342,
      likeCount: 890,
    ),
    ExploreCardModel(
      id: '2',
      authorName: 'Elena Rostova',
      authorHandle: '@elena_art',
      authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&auto=format&fit=crop',
      title: 'Ethereal Studio Portrait',
      previewUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop',
      category: 'Photorealism',
      maskedSummary: 'Natural Beauty • Hasselblad 100c • Soft Golden Hour • [Secret Recipe Encrypted]',
      remixFee: 5.0,
      creatorRoyaltyCut: 2.0,
      remixCount: 512,
      likeCount: 1420,
    ),
    ExploreCardModel(
      id: '3',
      authorName: 'Kaito Studio',
      authorHandle: '@kaito_anime',
      authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop',
      title: 'Mecha Angel Guardian',
      previewUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop',
      category: 'Anime',
      maskedSummary: 'Mecha Armor • Celestial Glow • Makoto Shinkai Style • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 219,
      likeCount: 654,
    ),
    ExploreCardModel(
      id: '4',
      authorName: 'Voxel Craft',
      authorHandle: '@voxel_craft',
      authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop',
      title: 'Obsidian Minimalist Watch',
      previewUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop',
      category: 'Product',
      maskedSummary: 'Matte Black • Volumetric Rim Lighting • Studio Pedestal • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 184,
      likeCount: 420,
    ),
  ].obs;

  List<ExploreCardModel> get filteredCards {
    if (selectedCategory.value == 'All') return cards;
    return cards.where((c) => c.category == selectedCategory.value).toList();
  }

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  void toggleLike(String id) {
    final idx = cards.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final card = cards[idx];
      final newLiked = !card.isLiked;
      cards[idx] = card.copyWith(
        isLiked: newLiked,
        likeCount: newLiked ? card.likeCount + 1 : card.likeCount - 1,
      );
    }
  }

  void useAsPrompt(ExploreCardModel card) {
    final studioCtrl = Get.find<StudioController>();
    final shellCtrl = Get.find<ShellController>();
    studioCtrl.loadPromptFromRemix(card);
    shellCtrl.switchTab(1); // switch to studio
  }

  void useAsRef(ExploreCardModel card) {
    final studioCtrl = Get.find<StudioController>();
    final shellCtrl = Get.find<ShellController>();
    studioCtrl.addReferenceImage(card.previewUrl);
    shellCtrl.switchTab(1); // switch to studio
  }
}
