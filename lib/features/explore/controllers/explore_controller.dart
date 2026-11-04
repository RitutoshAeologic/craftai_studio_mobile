import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:craftai_studio_mobile/core/utils/app_logger.dart';
import 'package:craftai_studio_mobile/data/models/explore_card_model.dart';
import 'package:craftai_studio_mobile/features/studio/presentation/controllers/studio_controller.dart';
import 'package:craftai_studio_mobile/features/shell/controllers/shell_controller.dart';
import '../domain/repositories/i_explore_repository.dart';
import '../data/repositories/explore_repository_impl.dart';

/// [ExploreController] manages the community discovery feed, style categorization,
/// multi-dimensional filtering (Category, Model, Aspect Ratio), and Studio remixes.
/// Follows Clean Architecture: Depends strictly on [IExploreRepository].
class ExploreController extends GetxController {
  final IExploreRepository _repository;

  ExploreController({IExploreRepository? repository})
      : _repository = repository ?? ExploreRepositoryImpl();

  /// Currently active category filter (default: 'All').
  final RxString selectedCategory = 'All'.obs;

  /// Currently active AI Model filter (default: 'All Models').
  final RxString selectedModel = 'All Models'.obs;

  /// Currently active Aspect Ratio filter set (default: {'All'}).
  final RxSet<String> selectedAspectRatios = _initAspectRatios();

  /// Helper to safely initialize non-empty RxSet without triggering
  /// RxInterface.proxy or premature Obx rebuilds during widget construction.
  static RxSet<String> _initAspectRatios() {
    final prevProxy = RxInterface.proxy;
    RxInterface.proxy = null;
    try {
      return <String>{'All'}.obs;
    } finally {
      RxInterface.proxy = prevProxy;
    }
  }

  /// Realtime search query for exploring community creations
  final RxString searchQuery = ''.obs;

  /// Whether search mode is active in the Explore feed
  final RxBool isSearching = false.obs;

  /// Number of cards loaded per pagination batch
  static const int kPageSize = 20;

  /// Active pagination page index (0-indexed)
  final RxInt currentPage = 0.obs;

  /// Whether initial cards are being fetched or refreshed
  final RxBool isInitialLoading = false.obs;

  /// Whether a subsequent page of cards is actively loading
  final RxBool isLoadingMore = false.obs;

  /// Whether more cards exist to be loaded from the backend/database
  final RxBool hasMoreCards = true.obs;

  /// Any error message during pagination fetch (null if healthy)
  final RxnString paginationError = RxnString();

  /// Available AI Models for dropdown filtering.
  final List<String> models = const [
    'All Models',
    'SDXL-Lightning',
    'FLUX.1 Schnell',
    'RealVisXL v4.0',
  ];

  /// Available Aspect Ratios for dropdown filtering.
  final List<String> aspectRatios = const [
    'All',
    '1:1',
    '16:9',
    '9:16',
    '4:5',
    '3:4',
  ];

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
      id: '00000000-0000-4000-8000-000000000001',
      authorName: 'Neo Akira',
      authorHandle: '@neo_akira',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop',
      title: 'Cyber Ronin in Rain',
      previewUrl: 'https://images.unsplash.com/photo-1578632767115-351597cf2477?w=600&auto=format&fit=crop',
      category: 'Cyberpunk',
      modelUsed: 'FLUX.1 Schnell',
      aspectRatio: '16:9',
      maskedSummary: 'Cyber Ronin • Wet Neon Street • 85mm Bokeh • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 342,
      likeCount: 890,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000002',
      authorName: 'Elena Rostova',
      authorHandle: '@elena_art',
      authorAvatar: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=100&auto=format&fit=crop',
      title: 'Ethereal Studio Portrait',
      previewUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=600&auto=format&fit=crop',
      category: 'Photorealism',
      modelUsed: 'RealVisXL v4.0',
      aspectRatio: '1:1',
      maskedSummary: 'Natural Beauty • Hasselblad 100c • Soft Golden Hour • [Secret Recipe Encrypted]',
      remixFee: 5.0,
      creatorRoyaltyCut: 2.0,
      remixCount: 512,
      likeCount: 1420,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000003',
      authorName: 'Kaito Studio',
      authorHandle: '@kaito_anime',
      authorAvatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=100&auto=format&fit=crop',
      title: 'Mecha Angel Guardian',
      previewUrl: 'https://images.unsplash.com/photo-1607604276583-eef5d076aa5f?w=600&auto=format&fit=crop',
      category: 'Anime',
      modelUsed: 'SDXL-Lightning',
      aspectRatio: '9:16',
      maskedSummary: 'Mecha Armor • Celestial Glow • Makoto Shinkai Style • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 219,
      likeCount: 654,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000004',
      authorName: 'Voxel Craft',
      authorHandle: '@voxel_craft',
      authorAvatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100&auto=format&fit=crop',
      title: 'Obsidian Minimalist Watch',
      previewUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=600&auto=format&fit=crop',
      category: 'Product',
      modelUsed: 'FLUX.1 Schnell',
      aspectRatio: '1:1',
      maskedSummary: 'Matte Black • Volumetric Rim Lighting • Studio Pedestal • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 184,
      likeCount: 420,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000005',
      authorName: 'Sora Tanaka',
      authorHandle: '@sora_cg',
      authorAvatar: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=100&auto=format&fit=crop',
      title: 'Neon Valkyrie 2099',
      previewUrl: 'https://images.unsplash.com/photo-1563089145-599997674d42?w=600&auto=format&fit=crop',
      category: 'Character',
      modelUsed: 'RealVisXL v4.0',
      aspectRatio: '9:16',
      maskedSummary: 'Valkyrie Armor • Electric Wings • Hyper-detailed Face • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 412,
      likeCount: 975,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000006',
      authorName: 'Studio Arch',
      authorHandle: '@arch_design',
      authorAvatar: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=100&auto=format&fit=crop',
      title: 'Nordic Cliffside Villa',
      previewUrl: 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=600&auto=format&fit=crop',
      category: 'Architecture',
      modelUsed: 'FLUX.1 Schnell',
      aspectRatio: '16:9',
      maskedSummary: 'Modern Concrete • Floor-to-ceiling Glass • Mist Valley • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 156,
      likeCount: 388,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000007',
      authorName: 'Pixar Magic',
      authorHandle: '@pixar_craft',
      authorAvatar: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&auto=format&fit=crop',
      title: 'Winter Fox Adventurer',
      previewUrl: 'https://images.unsplash.com/photo-1474511320723-9a56873867b5?w=600&auto=format&fit=crop',
      category: '3D Render',
      modelUsed: 'SDXL-Lightning',
      aspectRatio: '1:1',
      maskedSummary: 'Fluffy Red Fox • Knitted Beanie • Snow Sparkle • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 680,
      likeCount: 1890,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000008',
      authorName: 'Zara Vogue',
      authorHandle: '@zara_fashion',
      authorAvatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=100&auto=format&fit=crop',
      title: 'Haute Couture Liquid Silk',
      previewUrl: 'https://images.unsplash.com/photo-1496747611176-843222e1e57c?w=600&auto=format&fit=crop',
      category: 'Photorealism',
      modelUsed: 'RealVisXL v4.0',
      aspectRatio: '4:5',
      maskedSummary: 'Floating Emerald Silk • Dramatic Studio Shadows • 8K Textures • [Secret Recipe Encrypted]',
      remixFee: 5.0,
      creatorRoyaltyCut: 2.0,
      remixCount: 390,
      likeCount: 1120,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000009',
      authorName: 'Retro Wave',
      authorHandle: '@retro_1985',
      authorAvatar: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=100&auto=format&fit=crop',
      title: 'Analog 1985 Street Rider',
      previewUrl: 'https://images.unsplash.com/photo-1558981806-ec527fa84c39?w=600&auto=format&fit=crop',
      category: 'Photorealism',
      modelUsed: 'SDXL-Lightning',
      aspectRatio: '16:9',
      maskedSummary: 'Leather Jacket • 35mm Kodachrome Grain • Direct Flash • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 845,
      likeCount: 2310,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000010',
      authorName: 'Nexus Cyber',
      authorHandle: '@nexus_3d',
      authorAvatar: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&auto=format&fit=crop',
      title: 'Cyberpunk Bio-Dome',
      previewUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=600&auto=format&fit=crop',
      category: 'Cyberpunk',
      modelUsed: 'FLUX.1 Schnell',
      aspectRatio: '16:9',
      maskedSummary: 'Bioluminescent Flora • Neon Glass Habitat • Unreal Engine 5 • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 290,
      likeCount: 740,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000011',
      authorName: 'Manga Blade',
      authorHandle: '@manga_blade',
      authorAvatar: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=100&auto=format&fit=crop',
      title: 'Samurai Spirit In Blossom',
      previewUrl: 'https://images.unsplash.com/photo-1524413840807-0c3cb6fa808d?w=600&auto=format&fit=crop',
      category: 'Anime',
      modelUsed: 'RealVisXL v4.0',
      aspectRatio: '9:16',
      maskedSummary: 'Katana Stance • Cherry Blossom Storm • Ukiyo-e Modern Blend • [Secret Recipe Encrypted]',
      remixFee: 4.0,
      creatorRoyaltyCut: 1.6,
      remixCount: 530,
      likeCount: 1470,
    ),
    ExploreCardModel(
      id: '00000000-0000-4000-8000-000000000012',
      authorName: 'Prism Form',
      authorHandle: '@prism_3d',
      authorAvatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&auto=format&fit=crop',
      title: 'Matte Iridescent Sphere',
      previewUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=600&auto=format&fit=crop',
      category: '3D Render',
      modelUsed: 'SDXL-Lightning',
      aspectRatio: '1:1',
      maskedSummary: 'Fluid Chrome • Holographic Caustics • Octane Render 8K • [Secret Recipe Encrypted]',
      remixFee: 3.0,
      creatorRoyaltyCut: 1.2,
      remixCount: 310,
      likeCount: 820,
    ),
  ].obs;

  @override
  void onInit() {
    super.onInit();
    fetchExploreCards(isRefresh: true);
  }

  /// Compatibility alias for initial load
  Future<void> fetchExploreCardsFromSupabase() async => fetchExploreCards(isRefresh: true);

  /// Fetches a paginated slice of published community prompts from Supabase
  /// using safe range query and [AsyncWorker] isolate deserialization.
  Future<void> fetchExploreCards({bool isRefresh = false}) async {
    if (isRefresh) {
      currentPage.value = 0;
      hasMoreCards.value = true;
      paginationError.value = null;
      isInitialLoading.value = true;
    } else {
      if (isLoadingMore.value || !hasMoreCards.value) return;
      isLoadingMore.value = true;
      paginationError.value = null;
    }

    try {
      final fetched = await _repository.getExploreCards(
        page: currentPage.value,
        pageSize: kPageSize,
        category: selectedCategory.value,
        model: selectedModel.value,
        aspectRatios: selectedAspectRatios,
        searchQuery: searchQuery.value,
      );

      if (isRefresh) {
        if (fetched.isNotEmpty) {
          final fetchedIds = fetched.map((c) => c.id).toSet();
          final remainingLocal = cards.where((c) => !fetchedIds.contains(c.id) && c.id.startsWith('00000000')).toList();
          cards.assignAll([...fetched, ...remainingLocal]);
        }
      } else {
        final existingIds = cards.map((c) => c.id).toSet();
        final newItems = fetched.where((c) => !existingIds.contains(c.id)).toList();
        cards.addAll(newItems);
      }

      if (fetched.length < kPageSize) {
        hasMoreCards.value = false;
      } else {
        currentPage.value++;
      }
      AppLogger.s('Explore page ${currentPage.value} loaded (${fetched.length} items)', tag: 'EXPLORE');
    } catch (e) {
      AppLogger.w('Explore pagination error: $e', tag: 'EXPLORE');
      paginationError.value = 'Failed to load creations. Tap to retry.';
    } finally {
      isInitialLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Triggers next page load when scrolling near bottom of feed
  Future<void> loadMoreCards() async => fetchExploreCards(isRefresh: false);

  /// Pull-to-refresh handler
  Future<void> refreshCards() async => fetchExploreCards(isRefresh: true);

  /// Returns cards filtered across Search Query, Category, AI Model, and Aspect Ratio
  List<ExploreCardModel> get filteredCards {
    final query = searchQuery.value.trim().toLowerCase();
    return cards.where((c) {
      // 0. Search Query Filter
      if (query.isNotEmpty) {
        final matchesTitle = c.title.toLowerCase().contains(query);
        final matchesPrompt = c.maskedSummary.toLowerCase().contains(query);
        final matchesCategory = c.category.toLowerCase().contains(query);
        final matchesAuthor = c.authorName.toLowerCase().contains(query) ||
            c.authorHandle.toLowerCase().contains(query);
        final matchesModel = c.modelUsed.toLowerCase().contains(query);
        if (!matchesTitle &&
            !matchesPrompt &&
            !matchesCategory &&
            !matchesAuthor &&
            !matchesModel) {
          return false;
        }
      }

      // 1. Category Filter
      if (selectedCategory.value != 'All' && c.category != selectedCategory.value) {
        return false;
      }

      // 2. AI Model Filter
      if (selectedModel.value != 'All Models') {
        final selectedClean = selectedModel.value.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        final cardClean = c.modelUsed.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
        final matchFlux = selectedClean.contains('flux') && cardClean.contains('flux');
        final matchSdxl = selectedClean.contains('sdxl') && cardClean.contains('sdxl');
        final matchRealvis = selectedClean.contains('realvis') && cardClean.contains('realvis');
        if (!matchFlux && !matchSdxl && !matchRealvis && !cardClean.contains(selectedClean) && !selectedClean.contains(cardClean)) {
          return false;
        }
      }

      // 3. Aspect Ratio Filter
      if (!selectedAspectRatios.contains('All')) {
        if (!selectedAspectRatios.contains(c.aspectRatio)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Updates active text search query
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  /// Clears active search
  void clearSearch() {
    searchQuery.value = '';
    isSearching.value = false;
  }

  /// Changes the active category filter and re-filters the feed.
  void setCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    fetchExploreCards(isRefresh: true);
  }

  /// Changes the active AI Model filter and re-filters the feed.
  void setModel(String model) {
    if (selectedModel.value == model) return;
    selectedModel.value = model;
    fetchExploreCards(isRefresh: true);
  }

  /// Changes the active Aspect Ratio filter and re-filters the feed.
  void setAspectRatio(String ratio) {
    selectedAspectRatios.assignAll({ratio});
    fetchExploreCards(isRefresh: true);
  }

  /// Applies composite multi-dimensional filters
  void applyFilters({
    required String category,
    required String model,
    required Set<String> aspectRatios,
  }) {
    selectedCategory.value = category;
    selectedModel.value = model;
    selectedAspectRatios.assignAll(aspectRatios);
    fetchExploreCards(isRefresh: true);
  }

  /// Resets all filters back to default
  void resetFilters() {
    selectedCategory.value = 'All';
    selectedModel.value = 'All Models';
    selectedAspectRatios.assignAll({'All'});
    searchQuery.value = '';
    fetchExploreCards(isRefresh: true);
  }

  /// Total count of active non-default filters currently applied
  int get activeFilterCount {
    int count = 0;
    if (selectedCategory.value != 'All') count++;
    if (selectedModel.value != 'All Models') count++;
    if (!selectedAspectRatios.contains('All')) count++;
    if (searchQuery.value.trim().isNotEmpty) count++;
    return count;
  }

  /// Whether any non-default filter is currently active
  bool get hasActiveFilters => activeFilterCount > 0;

  /// Fetches similar creations from backend pgvector/similar endpoint via repository
  Future<List<ExploreCardModel>> fetchSimilarCreations(String cardId) async {
    try {
      final list = await _repository.getSimilarCreations(cardId);
      if (list.isNotEmpty) {
        return list;
      }
    } catch (e) {
      AppLogger.d('Similar creations fetch error fallback: $e', tag: 'EXPLORE');
    }

    // High-fidelity fallback: local category matching
    final currentCard = cards.firstWhereOrNull((c) => c.id == cardId);
    if (currentCard != null) {
      final sameCategory = cards.where((c) => c.category == currentCard.category && c.id != cardId).toList();
      if (sameCategory.length >= 4) {
        return [currentCard, ...sameCategory].take(8).toList();
      }
      final backfill = cards.where((c) => c.category != currentCard.category && c.id != cardId).toList();
      return [currentCard, ...sameCategory, ...backfill].take(8).toList();
    }
    return cards.take(8).toList();
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
      _repository.toggleLike(id, newLiked);
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
    String? modelUsed,
    String? aspectRatio,
    String? dimensions,
    int? seed,
    String? authorName,
    String? authorHandle,
    double remixFee = 4.0,
    double creatorRoyaltyCut = 1.6,
  }) {
    final newCard = ExploreCardModel(
      id: '00000000-0000-4000-8000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0')}',
      authorName: authorName ?? 'You',
      authorHandle: authorHandle ?? '@creator',
      authorAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=100&auto=format&fit=crop',
      title: title,
      previewUrl: previewUrl,
      category: category,
      modelUsed: modelUsed ?? 'FLUX.1 Schnell',
      aspectRatio: aspectRatio ?? '1:1',
      dimensions: dimensions ?? '1024x1024',
      seed: seed ?? 42,
      maskedSummary: prompt,
      remixFee: remixFee,
      creatorRoyaltyCut: creatorRoyaltyCut, // 40% royalty split
      remixCount: 0,
      likeCount: 1,
    );
    cards.insert(0, newCard);
  }
}
