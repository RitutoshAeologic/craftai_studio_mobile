import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';

/// [ExploreController] manages the community discovery feed, style categorization,
/// card interactions, and seamless transitions into Studio remix workflows.
class ExploreController extends GetxController {
  /// Currently active category filter (default: 'All').
  final RxString selectedCategory = 'All'.obs;

  /// Available style and prompt categories in the community feed.
  final RxList<String> categories = <String>[
    'All',
    'Photorealism',
    'Anime',
    'Cyberpunk',
    '3D Render',
    'Character',
    'Architecture',
    'Product',
  ].obs;

  /// Community-curated prompt and style cards.
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
    ExploreCardModel(
      id: '5',
      authorName: 'Sora Tanaka',
      authorHandle: '@sora_cg',
      authorAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&auto=format&fit=crop',
      title: 'Neon Valkyrie 2099',
      previewUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop',
      category: 'Character',
      maskedSummary: 'Valkyrie Armor • Electric Wings • Hyper-detailed Face • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 412,
      likeCount: 975,
    ),
    ExploreCardModel(
      id: '6',
      authorName: 'Studio Arch',
      authorHandle: '@arch_design',
      authorAvatar: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100&auto=format&fit=crop',
      title: 'Nordic Cliffside Villa',
      previewUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&auto=format&fit=crop',
      category: 'Architecture',
      maskedSummary: 'Modern Concrete • Floor-to-ceiling Glass • Mist Valley • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 156,
      likeCount: 388,
    ),
    ExploreCardModel(
      id: '7',
      authorName: 'Pixar Magic',
      authorHandle: '@pixar_craft',
      authorAvatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop',
      title: 'Winter Fox Adventurer',
      previewUrl: 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=600&auto=format&fit=crop',
      category: '3D Render',
      maskedSummary: 'Fluffy Red Fox • Knitted Beanie • Snow Sparkle • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 680,
      likeCount: 1890,
    ),
    ExploreCardModel(
      id: '8',
      authorName: 'Zara Vogue',
      authorHandle: '@zara_fashion',
      authorAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop',
      title: 'Haute Couture Liquid Silk',
      previewUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600&auto=format&fit=crop',
      category: 'Photorealism',
      maskedSummary: 'Floating Emerald Silk • Dramatic Studio Shadows • 8K Textures • [Secret Recipe Encrypted]',
      remixFee: 5.0,
      creatorRoyaltyCut: 2.0,
      remixCount: 390,
      likeCount: 1120,
    ),
    ExploreCardModel(
      id: '9',
      authorName: 'Retro Wave',
      authorHandle: '@retro_1985',
      authorAvatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&auto=format&fit=crop',
      title: 'Analog 1985 Street Rider',
      previewUrl: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=600&auto=format&fit=crop',
      category: 'Photorealism',
      maskedSummary: 'Leather Jacket • 35mm Kodachrome Grain • Direct Flash • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 845,
      likeCount: 2310,
    ),
    ExploreCardModel(
      id: '10',
      authorName: 'Nexus Cyber',
      authorHandle: '@nexus_3d',
      authorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop',
      title: 'Cyberpunk Bio-Dome',
      previewUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop',
      category: 'Cyberpunk',
      maskedSummary: 'Bioluminescent Flora • Neon Glass Habitat • Unreal Engine 5 • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 290,
      likeCount: 740,
    ),
    ExploreCardModel(
      id: '11',
      authorName: 'Manga Blade',
      authorHandle: '@manga_blade',
      authorAvatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop',
      title: 'Samurai Spirit In Blossom',
      previewUrl: 'https://images.unsplash.com/photo-1528164344705-475426879c0d?w=600&auto=format&fit=crop',
      category: 'Anime',
      maskedSummary: 'Katana Stance • Cherry Blossom Storm • Ukiyo-e Modern Blend • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 530,
      likeCount: 1470,
    ),
    ExploreCardModel(
      id: '12',
      authorName: 'Prism Form',
      authorHandle: '@prism_3d',
      authorAvatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop',
      title: 'Matte Iridescent Sphere',
      previewUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop',
      category: '3D Render',
      maskedSummary: 'Fluid Chrome • Holographic Caustics • Octane Render 8K • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 310,
      likeCount: 820,
    ),
  ].obs;

  /// Returns cards filtered by the active [selectedCategory].
  List<ExploreCardModel> get filteredCards {
    if (selectedCategory.value == 'All') return cards;
    return cards.where((c) => c.category == selectedCategory.value).toList();
  }

  /// Changes the active category filter and re-filters the feed.
  void setCategory(String category) {
    selectedCategory.value = category;
  }

  /// Toggles like state and increments/decrements like counter on a card.
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

  /// Copies the card's prompt into the Creation Studio and navigates to the Studio tab.
  void useAsPrompt(ExploreCardModel card) {
    final studioCtrl = Get.find<StudioController>();
    final shellCtrl = Get.find<ShellController>();
    studioCtrl.loadPromptFromRemix(card);
    shellCtrl.switchTab(1); // switch to studio
  }

  /// Attaches the card's preview image as a reference photo in Studio and navigates.
  void useAsRef(ExploreCardModel card) {
    final studioCtrl = Get.find<StudioController>();
    final shellCtrl = Get.find<ShellController>();
    studioCtrl.addReferenceImage(card.previewUrl);
    shellCtrl.switchTab(1); // switch to studio
  }

  /// "⚡ Remix on My Photo" Action:
  /// Prompts the user to pick a photo from their device gallery, then applies
  /// the card's style to the photo using Subject-Lock in the Studio tab.
  Future<void> remixWithMyPhoto(ExploreCardModel card) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final studioCtrl = Get.find<StudioController>();
      final shellCtrl = Get.find<ShellController>();
      studioCtrl.remixOnMyPhoto(card, File(picked.path));
      shellCtrl.switchTab(1); // switch to studio
    }
  }

  /// Publishes a user creation from Library to the Explore community feed.
  void publishCreation({
    required String title,
    required String prompt,
    required String previewUrl,
    required String category,
  }) {
    final newCard = ExploreCardModel(
      id: 'pub_${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'You',
      authorHandle: '@creator',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop',
      title: title,
      previewUrl: previewUrl,
      category: category,
      maskedSummary: prompt,
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6, // 40% royalty split
      remixCount: 0,
      likeCount: 1,
    );
    cards.insert(0, newCard);
  }
}
